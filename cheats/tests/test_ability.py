from pathlib import Path
import importlib.util
import struct
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("ability", ROOT / "cheats/tools/add_god_ability.py")
ability = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ability)


class AbilityTests(unittest.TestCase):
    def test_existing_data_is_preserved_and_both_descriptions_are_tagged(self):
        source = struct.pack("<iii", 2, 0, 0)
        result = ability.add_god_ability(source)
        offset, count, ids = ability.read_table(result, 8)
        self.assertEqual((offset, count, ids), (len(result), 1, {b"ATwd"}))
        self.assertIn(b"AvulATwd", result)
        self.assertEqual(result.count(b"Updated by Rossoliny."), 2)
        real = (ROOT / "Objects/War3map.w3a").read_bytes()
        if b"ATwd" not in real:
            result = ability.add_god_ability(real)
            custom_offset = ability.read_table(real, 4)[0]
            self.assertEqual(result[:custom_offset], real[:custom_offset])
            old_end = ability.read_table(real, custom_offset)[0]
            self.assertEqual(result[custom_offset + 4:old_end], real[custom_offset + 4:old_end])
            self.assertTrue(result.endswith(real[old_end:]))

    def test_duplicate_or_bad_data_is_rejected(self):
        source = struct.pack("<iii", 2, 0, 0)
        with self.assertRaises(ValueError):
            ability.add_god_ability(ability.add_god_ability(source))
        with self.assertRaises(ValueError):
            ability.add_god_ability(source + b"extra")


if __name__ == "__main__":
    unittest.main()
