"""Exercise the real JASS mana and cooldown command handlers."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "cheats/tests"))
from test_commands import Game, rawcode


class CheatToggleTests(unittest.TestCase):
    def setUp(self):
        self.game = Game()
        self.hero = self.add_hero(0)
        self.other_hero = self.add_hero(1)
        self.cooldown_resets = []
        self.game.g.update({
            "GetUnitState": lambda unit, state: (
                unit.maximum_mana if state == "UNIT_STATE_MAX_MANA" else unit.mana),
            "SetUnitState": lambda unit, state, value: setattr(unit, "mana", value),
            "IsUnitAliveBJ": lambda unit: bool(unit and unit.kind and unit.life > 0),
            "TriggerSleepAction": lambda seconds: None,
            "UnitResetCooldown": self.cooldown_resets.append,
        })

    def add_hero(self, owner):
        hero = self.game.create_unit(owner, rawcode("H003"))
        hero.maximum_mana, hero.mana = 250.0, 30.0
        self.game.g["m"][owner + 1] = hero
        return hero

    def activate(self, player=0):
        self.game.command("-cheats bvo-rossoliny", player)

    def tick(self):
        self.game.g["TestCommands_Mana"]()

    def cast(self, hero):
        self.game.damage_target = hero
        self.game.g["TestCommands_Cooldown"]()

    def test_nomana_toggles_refill_on_off_on(self):
        self.activate()
        self.game.command("-nomana")
        self.assertEqual(self.hero.mana, 250.0)
        self.hero.mana = 5.0
        self.tick()
        self.assertEqual(self.hero.mana, 250.0)
        self.game.command("-nomana")
        self.hero.mana = 7.0
        self.tick()
        self.assertEqual(self.hero.mana, 7.0)
        self.game.command("-nomana")
        self.assertEqual(self.hero.mana, 250.0)

    def test_commands_require_personal_activation(self):
        self.activate(1)
        for command in ("-nomana", "-nocd"):
            self.game.command(command, 0)
            self.assertEqual(self.game.messages[-1][0], 0)
            self.assertIn("отказ", self.game.messages[-1][2])
        self.tick()
        self.cast(self.hero)
        self.assertEqual(self.hero.mana, 30.0)
        self.assertFalse(self.cooldown_resets)

    def test_nomana_is_personal_and_players_toggle_independently(self):
        self.activate()
        self.activate(1)
        self.game.command("-nomana", 0)
        self.tick()
        self.assertEqual(self.hero.mana, 250.0)
        self.assertEqual(self.other_hero.mana, 30.0)
        self.game.command("-nomana", 1)
        self.game.command("-nomana", 0)
        self.hero.mana = self.other_hero.mana = 6.0
        self.tick()
        self.assertEqual(self.hero.mana, 6.0)
        self.assertEqual(self.other_hero.mana, 250.0)

    def test_nomana_follows_current_hero(self):
        self.activate()
        self.game.command("-nomana")
        replacement = self.add_hero(0)
        self.hero.mana = 4.0
        self.tick()
        self.assertEqual(replacement.mana, 250.0)
        self.assertEqual(self.hero.mana, 4.0)

    def test_mana_alias_is_removed(self):
        self.activate()
        self.game.command("-mana")
        self.tick()
        self.assertEqual(self.hero.mana, 30.0)
        self.assertFalse(self.game.g["TestCommands_InfiniteMana"][0])

    def test_nocd_toggles_cooldown_resets(self):
        self.activate()
        self.game.command("-nocd")
        self.cast(self.hero)
        self.assertEqual(self.cooldown_resets, [self.hero])
        self.game.command("-nocd")
        self.cast(self.hero)
        self.assertEqual(self.cooldown_resets, [self.hero])
        self.game.command("-nocd")
        self.cast(self.hero)
        self.assertEqual(self.cooldown_resets, [self.hero, self.hero])

    def test_nocd_is_personal_and_nc_alias_is_removed(self):
        self.activate()
        self.activate(1)
        self.game.command("-nc")
        self.cast(self.hero)
        self.assertFalse(self.cooldown_resets)
        self.game.command("-nocd")
        self.cast(self.other_hero)
        self.assertFalse(self.cooldown_resets)
        self.cast(self.hero)
        self.assertEqual(self.cooldown_resets, [self.hero])

    def test_arguments_do_not_toggle_enabled_modes(self):
        self.activate()
        self.game.command("-nomana")
        self.game.command("-nocd")
        self.game.command("-nomana 0")
        self.assertIn("без параметров", self.game.messages[-1][2])
        self.game.command("-nocd off")
        self.assertIn("-nocd без параметров", self.game.messages[-1][2])
        self.hero.mana = 9.0
        self.tick()
        self.cast(self.hero)
        self.assertEqual(self.hero.mana, 250.0)
        self.assertEqual(self.cooldown_resets, [self.hero])

    def test_mana_and_cooldown_modes_are_independent(self):
        self.activate()
        self.game.command("-nomana")
        self.cast(self.hero)
        self.assertFalse(self.cooldown_resets)
        self.game.command("-nocd")
        self.game.command("-nomana")
        self.hero.mana = 10.0
        self.cast(self.hero)
        self.tick()
        self.assertEqual(self.cooldown_resets, [self.hero])
        self.assertEqual(self.hero.mana, 10.0)


if __name__ == "__main__":
    unittest.main()
