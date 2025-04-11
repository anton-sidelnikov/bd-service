import unittest
from datetime import datetime, timedelta

from utils import days_until_next_birthday, is_valid_dob, is_valid_username


class TestUtils(unittest.TestCase):

    def test_valid_usernames(self):
        self.assertTrue(is_valid_username("Alice"))
        self.assertTrue(is_valid_username("bob"))
        self.assertFalse(is_valid_username("bob123"))
        self.assertFalse(is_valid_username("john_doe"))

    def test_valid_date_of_birth(self):
        self.assertTrue(is_valid_dob("2000-01-01"))
        self.assertFalse(is_valid_dob("3020-01-01"))  # future
        self.assertFalse(is_valid_dob("not-a-date"))

    def test_days_until_next_birthday(self):
        today = datetime.now().date()
        next_day = today + timedelta(days=1)
        prev_day = today - timedelta(days=1)
        self.assertEqual(days_until_next_birthday(today), 0)
        self.assertEqual(days_until_next_birthday(next_day), 1)
        self.assertIn(days_until_next_birthday(prev_day), [364, 365])  # leap year edge


if __name__ == "__main__":
    unittest.main()
