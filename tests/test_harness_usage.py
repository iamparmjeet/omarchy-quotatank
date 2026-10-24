from test_backend import usage
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock


class HarnessUsageTests(unittest.TestCase):
    def test_wallet_currencies_stay_separate_and_funded_cny_is_visible(self):
        payload = {"code": 0, "data": {"biz_code": 0, "biz_data": {
            "normal_wallets": [{"currency": "USD", "balance": "0"}],
            "bonus_wallets": [{"currency": "CNY", "balance": "4.4656"}]}}}
        credits, notice = usage.parse_deepseek_harness(payload)
        self.assertEqual((credits["currency"], credits["remaining"]), ("CNY", 4.47))
        self.assertIn("USD 0.0000", notice)

    def test_failed_wallet_response_is_not_zero(self):
        with self.assertRaises(usage.ProviderFailure):
            usage.parse_deepseek_harness({"code": 0, "data": {"biz_code": 40003}})

    def test_only_official_harness_grant_is_read(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            (home / ".dsh").mkdir()
            p = home / ".dsh/.credentials.yaml"
            doc = "version: 1\nrecords:\n  deepseek-account-platform/default:\n    kind: grant\n    payload:\n      token: test_token\n      issuer: https://platform.deepseek.com\n"
            with mock.patch.object(usage.Path, "home", return_value=home):
                p.write_text(doc)
                self.assertEqual(usage.deepseek_harness_token(), "test_token")
                p.write_text(doc.replace("https://platform.deepseek.com", "https://example.invalid"))
                self.assertEqual(usage.deepseek_harness_token(), "")

    def balance(self):
        return {"code": 0, "data": {"plans": [{"user_plan_id": "p", "status": "active", "name": "Trial"}],
            "balances": [{"user_plan_id": "p", "entitlement_id": "flash", "show_name": "GLM-5.3-Flash",
                "total_units": 300, "used_units": 200, "remaining_units": 100, "expires_at": 4102444800}]}}

    def test_trial_allowance_has_no_invented_rolling_reset(self):
        windows, _ = usage.parse_zcode_balance(self.balance())
        self.assertEqual(windows[0]["used"], 66.67)
        self.assertIsNone(windows[0]["windowSeconds"])
        self.assertIsNone(windows[0]["resetsAt"])

    def test_unknown_and_expired_allowances_are_not_zero(self):
        p = self.balance()
        del p["data"]["balances"][0]["remaining_units"]
        with self.assertRaises(usage.ProviderFailure):
            usage.parse_zcode_balance(p)
        p = self.balance()
        p["data"]["balances"][0]["expires_at"] = 1
        with self.assertRaises(usage.ProviderFailure):
            usage.parse_zcode_balance(p)

    def test_markup_in_harness_labels_is_neutralized(self):
        p = self.balance()
        p["data"]["balances"][0]["show_name"] = '<img src="https://example.invalid">'
        p["data"]["plans"][0]["name"] = "<b>Trial</b>"
        windows, plan = usage.parse_zcode_balance(p)
        self.assertNotIn("<", windows[0]["label"])
        self.assertNotIn("<", plan)

    def test_cached_snapshot_keeps_original_time_and_skips_pacing(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            logs = home / ".zcode/v2/logs"
            logs.mkdir(parents=True)
            (logs / "2026-10-24.log").write_text('[2026-10-24 10:00:00.000] [usage-stats] billing/balance completed ' + json.dumps({"payload": self.balance()}) + '\n')
            with mock.patch.object(usage.Path, "home", return_value=home):
                result = usage.fetch_glm(1)
            self.assertEqual(result["status"], "ok")
            self.assertFalse(result["historyEligible"])
            self.assertIn("10:00:00", result["fetchedAt"])


if __name__ == "__main__":
    unittest.main()
