import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const target = path.resolve(process.argv[2] ?? "09_automation_skill/templates/exception_log_template.xlsx");
const workbook = Workbook.create();
const sheet = workbook.worksheets.add("Exception Log");
const headers = [
  "RefreshId", "DetectedAt", "RuleId", "Severity", "Dataset", "SourceFile",
  "ReportingMonth", "OrganisationCode", "RecordStatus", "ValidationReason",
  "Owner", "ResolutionStatus", "ResolutionNote"
];
sheet.getRange("A1:M1").values = [headers];
sheet.getRange("A1:M1").format = {
  fill: "#173F63", font: { bold: true, color: "#FFFFFF" },
  horizontalAlignment: "center", wrapText: true,
};
sheet.getRange("A2:M2").values = [[
  "Example only", "2025-03-31 09:00", "REF-001", "High", "Workforce",
  "workforce_staff_group_organisation_2025-03.csv", "2025-03-01", "RXXXX",
  "Review Required", "Organisation code not found in approved reference", "Data owner", "Open", "Replace or approve mapping"
]];
sheet.getRange("A2:M2").format.wrapText = true;
sheet.getRange("A1:M2").format.borders = { preset: "all", style: "thin", color: "#DCE5EA" };
sheet.getRange("A:M").format.columnWidth = 16;
sheet.getRange("F:F").format.columnWidth = 34;
sheet.getRange("J:J").format.columnWidth = 42;
sheet.getRange("M:M").format.columnWidth = 32;
sheet.freezePanes.freezeRows(1);
sheet.showGridLines = false;
const table = sheet.tables.add("A1:M2", true, "ExceptionLogTemplate");
table.style = "TableStyleMedium2";
const inspect = await workbook.inspect({ kind: "table", range: "A1:M2", tableMaxRows: 3, tableMaxCols: 13 });
if (!inspect.ndjson.includes("ValidationReason")) throw new Error("Exception template verification failed");
await fs.mkdir(path.dirname(target), { recursive: true });
const xlsx = await SpreadsheetFile.exportXlsx(workbook);
await xlsx.save(target);
console.log(`Created ${target}`);
