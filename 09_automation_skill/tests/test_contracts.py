import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from run_monthly_reporting import month_from_filename, status_for_code


class ContractTests(unittest.TestCase):
    def test_month_is_parsed_from_expected_filename(self):
        self.assertEqual(month_from_filename(Path("ae_activity_2025-03.csv")), "2025-03-01")

    def test_unknown_organisation_is_review_required(self):
        status, reason = status_for_code("R999", {})
        self.assertEqual(status, "Review Required")
        self.assertIn("not found", reason)

    def test_missing_organisation_is_rejected(self):
        status, reason = status_for_code("", {})
        self.assertEqual(status, "Rejected")
        self.assertIn("missing", reason)


if __name__ == "__main__":
    unittest.main()
