"""Reproducible Phase 10 investigation using the project's public NHS source files.

Question: Why did selected providers show poorer four-hour performance while
their workforce FTE remained broadly stable?
"""

from pathlib import Path
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = Path(__file__).resolve().parent / "outputs"
FTE_STABILITY_THRESHOLD_PCT = 3.5
PERFORMANCE_DETERIORATION_THRESHOLD_PP = -2.0


def load_workforce() -> pd.DataFrame:
    workforce = pd.read_csv(
        ROOT / "04_processed_data/reporting_sources/fact_workforce_report.csv"
    )
    workforce["ReportingMonth"] = pd.to_datetime(workforce["ReportingMonth"])
    return workforce.groupby(["ReportingMonth", "OrganisationCode"], as_index=False).agg(
        WorkforceFTE=("FTE", "sum"),
        Headcount=("Headcount", "sum"),
    )


def load_absence() -> pd.DataFrame:
    files = sorted((ROOT / "02_source_data/raw/absence").glob("*.csv"))
    absence = pd.concat([pd.read_csv(file) for file in files], ignore_index=True)
    absence["ReportingMonth"] = (
        pd.to_datetime(absence["DATE"], dayfirst=True).dt.to_period("M").dt.to_timestamp()
    )
    absence = absence.groupby(["ReportingMonth", "ORG_CODE"], as_index=False).agg(
        FTEDaysLost=("FTE_DAYS_LOST", "sum"),
        FTEDaysAvailable=("FTE_DAYS_AVAILABLE", "sum"),
    )
    absence["SicknessAbsenceRate"] = absence["FTEDaysLost"] / absence["FTEDaysAvailable"]
    return absence


def load_activity() -> pd.DataFrame:
    activity_frames = []
    for file in sorted((ROOT / "02_source_data/raw/service_activity").glob("*.csv")):
        activity = pd.read_csv(file)
        activity["ReportingMonth"] = pd.to_datetime(file.stem.split("_")[-1] + "-01")
        attendance_columns = [
            column for column in activity.columns if column.startswith("A&E attendances")
        ]
        over_four_columns = [
            column for column in activity.columns if column.startswith("Attendances over 4hrs")
        ]
        admission_columns = [
            column for column in activity.columns if column.startswith("Emergency admissions")
        ]
        activity["TotalAttendances"] = activity[attendance_columns].sum(axis=1)
        activity["AttendancesOverFourHours"] = activity[over_four_columns].sum(axis=1)
        activity["EmergencyAdmissions"] = activity[admission_columns].sum(axis=1)
        activity["Waits12PlusHoursDTA"] = activity[
            "Patients who have waited 12+ hrs from DTA to admission"
        ]
        activity_frames.append(
            activity[
                [
                    "ReportingMonth",
                    "Org Code",
                    "TotalAttendances",
                    "AttendancesOverFourHours",
                    "EmergencyAdmissions",
                    "Waits12PlusHoursDTA",
                ]
            ]
        )
    activity = pd.concat(activity_frames, ignore_index=True).groupby(
        ["ReportingMonth", "Org Code"], as_index=False
    ).sum(numeric_only=True)
    activity["FourHourPerformance"] = 1 - (
        activity["AttendancesOverFourHours"] / activity["TotalAttendances"]
    )
    return activity


def pct_change(current: float, baseline: float) -> float:
    return (current / baseline - 1) * 100 if baseline else float("nan")


def build_model() -> pd.DataFrame:
    reference = pd.read_csv(ROOT / "02_source_data/reference/dim_organisation.csv")
    cohort = reference[
        reference["InclusionFlag"].astype(str).str.lower().eq("true")
    ][["OrganisationCode", "CanonicalOrganisationName", "OrganisationType", "RegionName"]]
    model = (
        cohort.merge(load_workforce(), on="OrganisationCode", how="inner")
        .merge(
            load_absence(),
            left_on=["OrganisationCode", "ReportingMonth"],
            right_on=["ORG_CODE", "ReportingMonth"],
            how="inner",
        )
        .merge(
            load_activity(),
            left_on=["OrganisationCode", "ReportingMonth"],
            right_on=["Org Code", "ReportingMonth"],
            how="inner",
        )
    )
    model["EstimatedAvailableFTE"] = model["WorkforceFTE"] * (
        1 - model["SicknessAbsenceRate"]
    )
    return model.sort_values(["OrganisationCode", "ReportingMonth"])


def period_summary(frame: pd.DataFrame) -> dict:
    return {
        "WorkforceFTE": frame["WorkforceFTE"].mean(),
        "SicknessAbsenceRate": frame["FTEDaysLost"].sum() / frame["FTEDaysAvailable"].sum(),
        "EstimatedAvailableFTE": frame["EstimatedAvailableFTE"].mean(),
        "TotalAttendances": frame["TotalAttendances"].sum(),
        "EmergencyAdmissions": frame["EmergencyAdmissions"].sum(),
        "AttendancesOverFourHours": frame["AttendancesOverFourHours"].sum(),
        "Waits12PlusHoursDTA": frame["Waits12PlusHoursDTA"].sum(),
        "FourHourPerformance": 1
        - (frame["AttendancesOverFourHours"].sum() / frame["TotalAttendances"].sum()),
    }


def create_selection_table(model: pd.DataFrame) -> pd.DataFrame:
    april = model.loc[model["ReportingMonth"].eq(pd.Timestamp("2024-04-01"))].set_index(
        "OrganisationCode"
    )
    march = model.loc[model["ReportingMonth"].eq(pd.Timestamp("2025-03-01"))].set_index(
        "OrganisationCode"
    )
    selection = april[["CanonicalOrganisationName", "WorkforceFTE", "FourHourPerformance"]].join(
        march[["WorkforceFTE", "FourHourPerformance"]], lsuffix="April", rsuffix="March"
    )
    selection["FTEChangePct"] = (
        selection["WorkforceFTEMarch"] / selection["WorkforceFTEApril"] - 1
    ) * 100
    selection["FourHourPerformanceChangePP"] = (
        selection["FourHourPerformanceMarch"] - selection["FourHourPerformanceApril"]
    ) * 100
    selection["StableFTE"] = selection["FTEChangePct"].abs() <= FTE_STABILITY_THRESHOLD_PCT
    selection["DeterioratingPerformance"] = (
        selection["FourHourPerformanceChangePP"] <= PERFORMANCE_DETERIORATION_THRESHOLD_PP
    )
    selection["SelectedForReview"] = selection["StableFTE"] & selection["DeterioratingPerformance"]
    return selection.reset_index().sort_values("FourHourPerformanceChangePP")


def create_candidate_summary(model: pd.DataFrame, candidates: list[str]) -> pd.DataFrame:
    records = []
    for organisation_code in candidates:
        provider = model.loc[model["OrganisationCode"].eq(organisation_code)].copy()
        april = provider.loc[provider["ReportingMonth"].eq(pd.Timestamp("2024-04-01"))].iloc[0]
        march = provider.loc[provider["ReportingMonth"].eq(pd.Timestamp("2025-03-01"))].iloc[0]
        q1 = period_summary(provider.loc[provider["ReportingMonth"].dt.month.isin([4, 5, 6])])
        q4 = period_summary(provider.loc[provider["ReportingMonth"].dt.month.isin([1, 2, 3])])
        end_point = {
            "WorkforceFTEChangePct": pct_change(march.WorkforceFTE, april.WorkforceFTE),
            "FourHourPerformanceChangePP": (march.FourHourPerformance - april.FourHourPerformance) * 100,
            "SicknessAbsenceChangePP": (march.SicknessAbsenceRate - april.SicknessAbsenceRate) * 100,
            "EstimatedAvailableFTEChangePct": pct_change(
                march.EstimatedAvailableFTE, april.EstimatedAvailableFTE
            ),
            "AttendanceChangePct": pct_change(march.TotalAttendances, april.TotalAttendances),
            "EmergencyAdmissionsChangePct": pct_change(
                march.EmergencyAdmissions, april.EmergencyAdmissions
            ),
            "AttendancesOverFourHoursChangePct": pct_change(
                march.AttendancesOverFourHours, april.AttendancesOverFourHours
            ),
            "Waits12PlusHoursDTAChangePct": pct_change(
                march.Waits12PlusHoursDTA, april.Waits12PlusHoursDTA
            ),
        }
        quarterly = {
            "Q1ToQ4FTEChangePct": pct_change(q4["WorkforceFTE"], q1["WorkforceFTE"]),
            "Q1ToQ4FourHourPerformanceChangePP": (
                q4["FourHourPerformance"] - q1["FourHourPerformance"]
            )
            * 100,
            "Q1ToQ4SicknessAbsenceChangePP": (
                q4["SicknessAbsenceRate"] - q1["SicknessAbsenceRate"]
            )
            * 100,
            "Q1ToQ4EstimatedAvailableFTEChangePct": pct_change(
                q4["EstimatedAvailableFTE"], q1["EstimatedAvailableFTE"]
            ),
            "Q1ToQ4AttendanceChangePct": pct_change(
                q4["TotalAttendances"], q1["TotalAttendances"]
            ),
            "Q1ToQ4EmergencyAdmissionsChangePct": pct_change(
                q4["EmergencyAdmissions"], q1["EmergencyAdmissions"]
            ),
            "Q1ToQ4AttendancesOverFourHoursChangePct": pct_change(
                q4["AttendancesOverFourHours"], q1["AttendancesOverFourHours"]
            ),
            "Q1ToQ4Waits12PlusHoursDTAChangePct": pct_change(
                q4["Waits12PlusHoursDTA"], q1["Waits12PlusHoursDTA"]
            ),
        }
        records.append(
            {
                "OrganisationCode": organisation_code,
                "Organisation": april.CanonicalOrganisationName,
                "AprilFTE": april.WorkforceFTE,
                "MarchFTE": march.WorkforceFTE,
                "AprilFourHourPerformance": april.FourHourPerformance,
                "MarchFourHourPerformance": march.FourHourPerformance,
                "AprilSicknessAbsenceRate": april.SicknessAbsenceRate,
                "MarchSicknessAbsenceRate": march.SicknessAbsenceRate,
                "AprilEstimatedAvailableFTE": april.EstimatedAvailableFTE,
                "MarchEstimatedAvailableFTE": march.EstimatedAvailableFTE,
                "AprilAttendances": april.TotalAttendances,
                "MarchAttendances": march.TotalAttendances,
                "AprilEmergencyAdmissions": april.EmergencyAdmissions,
                "MarchEmergencyAdmissions": march.EmergencyAdmissions,
                "AprilOverFourHourAttendances": april.AttendancesOverFourHours,
                "MarchOverFourHourAttendances": march.AttendancesOverFourHours,
                "AprilWaits12PlusHoursDTA": april.Waits12PlusHoursDTA,
                "MarchWaits12PlusHoursDTA": march.Waits12PlusHoursDTA,
                **end_point,
                **quarterly,
            }
        )
    return pd.DataFrame(records)


def create_trend_chart(model: pd.DataFrame, candidates: list[str]) -> None:
    chart_data = model.loc[model["OrganisationCode"].isin(candidates)].copy()
    names = chart_data[["OrganisationCode", "CanonicalOrganisationName"]].drop_duplicates()
    width, height, panel_width = 1_200, 430, 540
    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="#F5F8FA"/>',
        '<text x="30" y="32" font-family="Segoe UI, Arial" font-size="18" font-weight="700" fill="#18313F">Four-hour performance trends for providers selected for review</text>',
    ]
    for index, code in enumerate(candidates):
        provider = chart_data.loc[chart_data["OrganisationCode"].eq(code)].reset_index(drop=True)
        name = names.loc[names["OrganisationCode"].eq(code), "CanonicalOrganisationName"].iloc[0]
        x0, y0, chart_w, chart_h = 40 + index * 580, 90, panel_width - 55, 240
        lines.extend([
            f'<rect x="{x0 - 15}" y="55" width="{panel_width}" height="330" rx="8" fill="#FFFFFF" stroke="#DCE5EA"/>',
            f'<text x="{x0}" y="82" font-family="Segoe UI, Arial" font-size="13" font-weight="700" fill="#18313F">{name.replace(" NHS Foundation Trust", "")}</text>',
        ])
        for value in [70, 75, 78, 80, 85]:
            y = y0 + (85 - value) / 20 * chart_h
            dash = ' stroke-dasharray="5 4"' if value == 78 else ''
            stroke = '#18313F' if value == 78 else '#DCE5EA'
            lines.append(f'<line x1="{x0}" y1="{y:.1f}" x2="{x0 + chart_w}" y2="{y:.1f}" stroke="{stroke}"{dash}/>')
            lines.append(f'<text x="{x0 - 5}" y="{y + 4:.1f}" text-anchor="end" font-family="Segoe UI, Arial" font-size="10" fill="#5A7184">{value}%</text>')
        points = []
        for position, row in provider.iterrows():
            x = x0 + position / (len(provider) - 1) * chart_w
            y = y0 + (85 - row.FourHourPerformance * 100) / 20 * chart_h
            points.append(f'{x:.1f},{y:.1f}')
            month = row.ReportingMonth.strftime('%b')
            lines.append(f'<text x="{x:.1f}" y="{y0 + chart_h + 22}" text-anchor="middle" font-family="Segoe UI, Arial" font-size="9" fill="#5A7184">{month}</text>')
        lines.append(f'<polyline points="{" ".join(points)}" fill="none" stroke="#2F75B5" stroke-width="3"/>')
        for point in points:
            x, y = point.split(',')
            lines.append(f'<circle cx="{x}" cy="{y}" r="3" fill="#2F75B5"/>')
        lines.append(f'<text x="{x0 + chart_w - 3}" y="{y0 + (85 - 78) / 20 * chart_h - 7:.1f}" text-anchor="end" font-family="Segoe UI, Arial" font-size="10" fill="#18313F">78% reference</text>')
    lines.append('</svg>')
    (OUTPUT / "four_hour_performance_trends.svg").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    model = build_model()
    selection = create_selection_table(model)
    selected_codes = selection.loc[selection["SelectedForReview"], "OrganisationCode"].tolist()
    candidates = create_candidate_summary(model, selected_codes)
    selection.to_csv(OUTPUT / "provider_selection_screen.csv", index=False)
    candidates.to_csv(OUTPUT / "selected_provider_driver_summary.csv", index=False)
    model.loc[model["OrganisationCode"].isin(selected_codes)].to_csv(
        OUTPUT / "selected_provider_monthly_series.csv", index=False
    )
    create_trend_chart(model, selected_codes)
    print(f"Cohort observations: {len(model):,}")
    print(f"Selected providers: {', '.join(selected_codes)}")


if __name__ == "__main__":
    main()
