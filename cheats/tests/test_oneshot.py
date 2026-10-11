"""Run the actual -oneshot JASS handlers against a Warcraft damage-event model.

Run: python -m unittest discover -s cheats/tests -p test_oneshot.py -v
"""
from collections import defaultdict
import unittest

from test_commands import Game, rawcode


class OneShotGame:
    def __init__(self):
        self.game = Game()
        self.chat_events = []
        self.enter_events = []
        self.damage_events = defaultdict(list)
        self.bonus_damage = []
        self.allies = {(0, 1), (1, 0)}
        self.source = self.game.create_unit(0, rawcode("H003"))
        self.target = self.game.create_unit(6, rawcode("N002"))
        self.game.g.update({
            "UNIT_STATE_MAX_LIFE": "UNIT_STATE_MAX_LIFE",
            "GetUnitState": lambda unit, state: 1000.0,
            "IsUnitEnemy": lambda unit, player: (
                unit.owner != player and (unit.owner, player) not in self.allies),
            "CreateTrigger": lambda: {"enabled": True, "actions": []},
            "TriggerAddAction": lambda trigger, action: trigger["actions"].append(action),
            "TriggerRegisterPlayerChatEvent": lambda trigger, player, text, exact:
                self.chat_events.append((trigger, player, text, exact)),
            "TriggerRegisterEnterRegion": lambda trigger, region, condition:
                self.enter_events.append(trigger),
            "TriggerRegisterUnitEvent": lambda trigger, unit, event:
                self.damage_events[unit].append(trigger),
            "UnitDamageTarget": self.deal_bonus_damage,
        })
        # Reinitialize with observable native event registration and existing units.
        if "TestCommands_OneShotDamageTrigger" in self.game.g:
            self.game.g["TestCommands_OneShotDamageTrigger"] = None
        self.game.g["TestCommands_Init"]()

    @staticmethod
    def dispatch(trigger):
        if trigger["enabled"]:
            for action in trigger["actions"]:
                action()

    def command(self, text, player=0):
        self.game.player, self.game.chat = player, text
        for trigger, registered_player, prefix, exact in self.chat_events:
            matches = text == prefix if exact else text.startswith(prefix)
            if player == registered_player and matches:
                self.dispatch(trigger)

    def activate(self, player=0):
        self.command("-cheats bvo-rossoliny", player)

    def new_unit(self, owner):
        unit = self.game.create_unit(owner, rawcode("H003"))
        self.game.entering = unit
        for trigger in self.enter_events:
            self.dispatch(trigger)
        return unit

    def damage(self, source, target, amount):
        old = self.game.damage_source, self.game.damage_target, self.game.damage_amount
        self.game.damage_source = source
        self.game.damage_target = target
        self.game.damage_amount = amount
        try:
            for trigger in self.damage_events[target]:
                self.dispatch(trigger)
            target.life -= amount
        finally:
            self.game.damage_source, self.game.damage_target, self.game.damage_amount = old

    def deal_bonus_damage(self, source, target, amount, *damage_types):
        self.bonus_damage.append((source, target, amount, damage_types))
        if len(self.bonus_damage) > 10:
            raise AssertionError("Bonus damage recursively triggered itself")
        self.damage(source, target, amount)
        return True


class OneShotTests(unittest.TestCase):
    def setUp(self):
        self.world = OneShotGame()

    def enable(self, player=0):
        self.world.activate(player)
        self.world.command("-oneshot", player)

    def test_requires_personal_cheat_activation(self):
        self.world.activate(1)
        self.world.command("-oneshot", 0)
        self.world.damage(self.world.source, self.world.target, 10.0)
        self.assertEqual(self.world.target.life, 990.0)
        self.assertFalse(self.world.bonus_damage)
        self.assertTrue(any(player == 0 and command == "-oneshot" and "отказ" in message
                            for player, command, message in self.world.game.messages))

    def test_repeated_command_toggles_on_off_on(self):
        self.enable()
        self.world.damage(self.world.source, self.world.target, 10.0)
        self.assertLessEqual(self.world.target.life, 0.0)
        self.world.command("-oneshot")
        self.world.target.life = 1000.0
        self.world.damage(self.world.source, self.world.target, 10.0)
        self.assertEqual(self.world.target.life, 990.0)
        self.world.command("-oneshot")
        self.world.damage(self.world.source, self.world.target, 10.0)
        self.assertLessEqual(self.world.target.life, 0.0)
        self.assertEqual(len(self.world.bonus_damage), 2)

    def test_other_players_do_not_gain_bonus(self):
        self.enable()
        another_source = self.world.new_unit(2)
        self.world.damage(another_source, self.world.target, 10.0)
        self.assertEqual(self.world.target.life, 990.0)
        self.assertFalse(self.world.bonus_damage)

    def test_adds_maximum_hp_once_and_keeps_original_attacker(self):
        self.enable()
        self.world.target.life = 400.0
        self.world.damage(self.world.source, self.world.target, 0.25)
        self.assertEqual(len(self.world.bonus_damage), 1)
        source, target, amount, damage_types = self.world.bonus_damage[0]
        self.assertIs(source, self.world.source)
        self.assertIs(target, self.world.target)
        self.assertEqual(amount, 1000.0)
        self.assertEqual(damage_types, (True, False, "ATTACK_TYPE_CHAOS",
                                       "DAMAGE_TYPE_UNIVERSAL", "WEAPON_TYPE_WHOKNOWS"))
        self.assertLessEqual(target.life, 0.0)
        self.assertTrue(self.world.game.g["TestCommands_OneShotDamageTrigger"]["enabled"])

    def test_new_owned_units_and_new_targets_receive_effect(self):
        self.enable()
        source, target = self.world.new_unit(0), self.world.new_unit(6)
        self.world.damage(source, target, 1.0)
        self.assertLessEqual(target.life, 0.0)
        self.assertEqual(len(self.world.bonus_damage), 1)

    def test_friendly_and_self_damage_are_not_amplified(self):
        self.enable()
        ally = self.world.new_unit(1)
        self.world.damage(self.world.source, ally, 10.0)
        self.world.damage(self.world.source, self.world.source, 10.0)
        self.assertEqual(ally.life, 990.0)
        self.assertEqual(self.world.source.life, 990.0)
        self.assertFalse(self.world.bonus_damage)

    def test_zero_damage_does_not_trigger_bonus(self):
        self.enable()
        self.world.damage(self.world.source, self.world.target, 0.0)
        self.assertEqual(self.world.target.life, 1000.0)
        self.assertFalse(self.world.bonus_damage)

    def test_arguments_are_rejected_without_toggling(self):
        self.world.activate()
        self.world.command("-oneshot 100")
        self.world.damage(self.world.source, self.world.target, 10.0)
        self.assertEqual(self.world.target.life, 990.0)
        self.assertTrue(any(command == "-oneshot" and "без параметров" in message
                            for player, command, message in self.world.game.messages))
        self.world.command("-oneshot")
        self.world.command("-oneshot 0")
        self.world.damage(self.world.source, self.world.target, 1.0)
        self.assertLessEqual(self.world.target.life, 0.0)

    def test_current_owner_controls_bonus_after_owner_change(self):
        self.enable()
        self.world.source.owner = 2
        self.world.damage(self.world.source, self.world.target, 10.0)
        self.assertEqual(self.world.target.life, 990.0)
        self.world.source.owner = 0
        self.world.damage(self.world.source, self.world.target, 1.0)
        self.assertLessEqual(self.world.target.life, 0.0)

    def test_access_gate_is_checked_on_every_damage_event(self):
        self.enable()
        self.world.game.g["TestCommands_Access"][0] = False
        self.world.damage(self.world.source, self.world.target, 10.0)
        self.assertEqual(self.world.target.life, 990.0)
        self.assertFalse(self.world.bonus_damage)

    def test_registration_and_initialization_are_idempotent(self):
        self.enable()
        handler = self.world.game.g.get("TestCommands_OneShotRegisterUnit")
        initializer = self.world.game.g.get("TestCommands_OneShotInit")
        if handler:
            handler(self.world.target)
        if initializer:
            initializer()
        self.world.damage(self.world.source, self.world.target, 1.0)
        self.assertEqual(len(self.world.bonus_damage), 1)
        self.assertEqual(len(self.world.damage_events[self.world.target]), 1)


if __name__ == "__main__":
    unittest.main()
