"""Execute the real JASS cheat functions against a small Warcraft 1.26 model.

Run: python -m unittest discover -s cheats/tests -v
The model covers chat routing, dialogs, inventory, ownership and damage events;
pjass separately checks the complete script against the game's native API.
"""
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def rawcode(value):
    return int.from_bytes(value.encode("ascii"), "big")


@dataclass(eq=False)
class Unit:
    owner: int
    kind: int = rawcode("H003")
    x: float = 100.0
    y: float = 200.0
    life: float = 1000.0
    level: int = 1
    paused: bool = False
    abilities: set = field(default_factory=set)
    items: list = field(default_factory=lambda: [None] * 6)


class Game:
    def __init__(self):
        self.units, self.messages, self.dialogs = [], [], []
        self.player, self.chat = 0, ""
        self.damage_target = self.damage_source = self.enum = self.entering = None
        self.damage_amount = 0.0
        self.clicked = None
        self.gold = defaultdict(lambda: 1000)
        self.g = {"__builtins__": __builtins__}
        text = (ROOT / "Current Script/war3map.j").read_text(encoding="utf-8")
        declarations = text.split("endglobals", 1)[0]
        for kind, array, name, initial in re.findall(
                r"^\s*(\w+)\s+(array\s+)?(\w+)(?:\s*=\s*([^\n]+))?$",
                declarations, re.M):
            default = False if kind == "boolean" else 0 if kind in ("integer", "real") else None
            self.g[name] = defaultdict(lambda d=default: d) if array else default
        constants = ["UNIT_TYPE_HERO", "UNIT_TYPE_DEAD", "PLAYER_STATE_RESOURCE_GOLD",
                     "PLAYER_STATE_RESOURCE_LUMBER", "UNIT_STATE_MANA", "UNIT_STATE_MAX_MANA",
                     "MAP_CONTROL_USER", "PLAYER_SLOT_STATE_PLAYING", "EVENT_PLAYER_UNIT_SPELL_EFFECT",
                     "EVENT_PLAYER_UNIT_CHANGE_OWNER", "EVENT_UNIT_DAMAGED", "ATTACK_TYPE_CHAOS",
                     "DAMAGE_TYPE_UNIVERSAL", "WEAPON_TYPE_WHOKNOWS", "bj_UNIT_FACING"]
        self.g.update({name: name for name in constants})
        self.g.update({
            "Player": lambda p: p, "GetPlayerId": lambda p: p,
            "GetTriggerPlayer": lambda: self.player, "GetEventPlayerChatString": lambda: self.chat,
            "GetOwningPlayer": lambda u: u.owner if u else 15,
            "GetUnitTypeId": lambda u: u.kind if u else 0,
            "GetUnitX": lambda u: u.x, "GetUnitY": lambda u: u.y,
            "GetUnitFacing": lambda u: 270.0,
            "GetWidgetLife": lambda u: u.life,
            "GetHeroLevel": lambda u: u.level,
            "GetUnitAbilityLevel": lambda u, a: int(a in u.abilities),
            "IsUnitType": lambda u, t: bool(u and u.kind and (u.life <= 0 if t == "UNIT_TYPE_DEAD" else True)),
            "IsUnitPaused": lambda u: u.paused,
            "IsUnitEnemy": lambda u, p: u.owner != p,
            "UnitAddAbility": lambda u, a: u.abilities.add(a),
            "UnitRemoveAbility": lambda u, a: u.abilities.discard(a),
            "UnitMakeAbilityPermanent": lambda *args: True,
            "UnitStripHeroLevel": lambda u, n: setattr(u, "level", u.level - n),
            "SetHeroLevel": lambda u, n, fx: setattr(u, "level", n),
            "GetUnitState": lambda *args: 100.0,
            "SetUnitState": lambda *args: None,
            "PauseUnit": lambda u, paused: setattr(u, "paused", paused),
            "GetPlayerState": lambda p, state: self.gold[p],
            "AdjustPlayerStateBJ": lambda n, p, state: self.gold.__setitem__(p, self.gold[p] + n),
            "SetPlayerState": lambda p, state, n: self.gold.__setitem__(p, n),
            "StringLength": len, "SubString": lambda s, a, b: s[a:b],
            "StringCase": lambda s, upper: s.upper() if upper else s.lower(),
            "S2I": lambda s: int(s) if re.fullmatch(r"-?\d+", s) else 0,
            "I2S": str, "R2I": int, "I2R": float, "ModuloInteger": lambda a, b: a % b,
            "GetObjectName": lambda code: f"Hero {code}", "GetUnitName": lambda u: "Hero",
            "GetHeroProperName": lambda u: "Hero",
            "GetEnumUnit": lambda: self.enum,
            "GetEnteringUnit": lambda: self.entering,
            "GetTriggerUnit": lambda: self.damage_target,
            "GetEventDamageSource": lambda: self.damage_source,
            "GetEventDamage": lambda: self.damage_amount,
            "CreateGroup": set, "DestroyGroup": lambda g: None,
            "GroupAddUnit": lambda g, u: g.add(u),
            "GroupRemoveUnit": lambda g, u: g.discard(u),
            "IsUnitInGroup": lambda u, g: u in g,
            "FirstOfGroup": lambda g: next(iter(g), None),
            "GroupEnumUnitsInRect": lambda g, rect, filt: g.update(u for u in self.units if u.kind),
            "ForGroup": self.for_group,
            "GetWorldBounds": lambda: object(), "RemoveRect": lambda *args: None,
            "CreateRegion": lambda: object(), "RegionAddRect": lambda *args: None,
            "CreateTrigger": lambda: {"enabled": True},
            "DisableTrigger": lambda t: t.update(enabled=False),
            "EnableTrigger": lambda t: t.update(enabled=True),
            "TriggerRegisterUnitEvent": lambda *args: None,
            "TriggerRegisterEnterRegion": lambda *args: None,
            "TriggerRegisterPlayerUnitEvent": lambda *args: None,
            "TriggerRegisterPlayerChatEvent": lambda *args: None,
            "TriggerRegisterTimerEventPeriodic": lambda *args: None,
            "TriggerAddAction": lambda *args: None,
            "TriggerExecute": lambda *args: None,
            "GetPlayerController": lambda p: "MAP_CONTROL_USER",
            "GetPlayerSlotState": lambda p: "PLAYER_SLOT_STATE_PLAYING",
            "DialogCreate": self.dialog_create,
            "DialogClear": lambda d: d["buttons"].clear(),
            "DialogSetMessage": lambda d, msg: d.update(message=msg),
            "DialogAddButton": self.dialog_button,
            "DialogDisplay": lambda p, d, show: d.update(visible=show),
            "TriggerRegisterDialogEvent": lambda *args: None,
            "GetClickedButton": lambda: self.clicked,
            "UnitItemInSlot": lambda u, i: u.items[i],
            "UnitRemoveItem": self.remove_item, "UnitAddItem": self.add_item,
            "CreateUnit": self.create_unit, "RemoveUnit": self.remove_unit,
            "SetUnitPosition": lambda u, x, y: (setattr(u, "x", x), setattr(u, "y", y)),
            "GetRectCenterX": lambda r: 0.0, "GetRectCenterY": lambda r: 0.0,
            "RemoveUnitFromAllStock": lambda *args: None,
            "SetPlayerUnitAvailableBJ": lambda *args: None,
            "SelectUnitForPlayerSingle": lambda *args: None,
            "PanCameraToTimedForPlayer": lambda *args: None,
            "SetCameraTargetControllerNoZForPlayer": lambda *args: None,
            "UnitDamageTarget": self.damage,
        })
        bodies = re.findall(r"^function (\w+) takes (.*?) returns (\w+)\n(.*?)^endfunction", text, re.M | re.S)
        for name, params, result, body in bodies:
            if name.startswith("TestCommands_") or name in ("hBx", "Hlx", "hbx", "HKx"):
                self.compile(name, params, body)
        self.g["TestCommands_Message"] = lambda p, command, result: self.messages.append((p, command, result))
        self.g["n"], self.g["o"], self.g["C4"] = set(), set(), set()
        self.g["TestCommands_Init"]()

    def compile(self, name, params, body):
        params = [] if params == "nothing" else [p.split()[-1] for p in params.split(",")]
        local = set(params)
        local.update(re.findall(r"^\s*local \w+ (\w+)", body, re.M))
        assigned = set(re.findall(r"^\s*set (\w+)\s*=", body, re.M)) - local
        lines = [f"def {name}({', '.join(params)}):"]
        if assigned:
            lines.append("    global " + ", ".join(sorted(assigned)))
        indent = 1
        for line in body.splitlines():
            line = line.strip()
            if not line or line.startswith("//"):
                continue
            line = re.sub(r"'(.{4})'", lambda m: str(rawcode(m[1])), line)
            # Replace JASS keywords only outside quoted strings.
            pieces = re.split(r'("(?:\\.|[^"\\])*")', line)
            for i in range(0, len(pieces), 2):
                pieces[i] = re.sub(r"\btrue\b", "True", pieces[i])
                pieces[i] = re.sub(r"\bfalse\b", "False", pieces[i])
                pieces[i] = re.sub(r"\bnull\b", "None", pieces[i])
                pieces[i] = re.sub(r"\bfunction\s+(\w+)", r"\1", pieces[i])
            line = "".join(pieces)
            if line in ("endif", "endloop"):
                indent -= 1
                continue
            if line.startswith("elseif ") or line == "else":
                indent -= 1
                line = "elif " + line[7:-4].strip() + ":" if line.startswith("elseif ") else "else:"
                lines.append("    " * indent + line)
                indent += 1
                continue
            if line.startswith("local "):
                declaration = re.sub(r"^local \w+ ", "", line)
                line = declaration if "=" in declaration else declaration + " = None"
            elif line.startswith("set "):
                line = line[4:]
            elif line.startswith("call "):
                line = line[5:]
            elif line == "loop":
                lines.append("    " * indent + "while True:")
                indent += 1
                continue
            elif line.startswith("exitwhen "):
                line = "if " + line[9:] + ": break"
            elif line.startswith("if") and line.endswith("then"):
                lines.append("    " * indent + "if " + line[2:-4].strip() + ":")
                indent += 1
                continue
            lines.append("    " * indent + line)
        try:
            exec("\n".join(lines), self.g)
        except Exception:
            raise RuntimeError("\n".join(lines))

    def create_unit(self, player, kind, x=100.0, y=200.0, facing=270.0):
        unit = Unit(player, kind, x, y)
        self.units.append(unit)
        if "TestCommands_Entering" in self.g:
            self.entering = unit
            self.g["TestCommands_Entering"]()
        return unit

    def remove_unit(self, unit):
        unit.kind = 0
        for value in self.g.values():
            if isinstance(value, set): value.discard(unit)

    def for_group(self, group, action):
        for unit in list(group):
            self.enum = unit
            action()

    def dialog_create(self):
        dialog = {"buttons": [], "visible": False}
        self.dialogs.append(dialog)
        return dialog

    def dialog_button(self, dialog, label, hotkey):
        button = object()
        dialog["buttons"].append((button, label))
        return button

    @staticmethod
    def remove_item(unit, item):
        unit.items[unit.items.index(item)] = None

    @staticmethod
    def add_item(unit, item):
        unit.items[unit.items.index(None)] = item
        return True

    def command(self, text, player=0):
        self.player, self.chat = player, text
        self.g["TestCommands_Commands"]()

    def damage(self, source, target, amount, *args):
        if rawcode("ATwd") in target.abilities or rawcode("Avul") in target.abilities:
            return False
        old = self.damage_source, self.damage_target, self.damage_amount
        self.damage_source, self.damage_target, self.damage_amount = source, target, amount
        trigger = self.g.get("TestCommands_DamageTrigger")
        if trigger and trigger["enabled"]:
            self.g["TestCommands_Damage"]()
        target.life -= amount
        self.damage_source, self.damage_target, self.damage_amount = old
        return True


class CheatsTests(unittest.TestCase):
    def setUp(self):
        self.game = Game()
        self.hero = self.game.create_unit(0, rawcode("H003"))
        self.game.g["m"][1] = self.hero

    def activate(self, player=0):
        self.game.command("-cheats bvo-rossoliny", player)

    def tick(self):
        self.game.g["TestCommands_Mana"]()
        self.game.g["TestCommands_GodTick"]()

    def test_god_mode_requires_personal_activation(self):
        self.game.command("-whosyourdaddy")
        self.assertNotIn(rawcode("ATwd"), self.hero.abilities)
        self.activate(1)
        self.game.command("-whosyourdaddy")
        self.assertNotIn(rawcode("ATwd"), self.hero.abilities)

    def test_god_mode_kills_enemy_and_preserves_normal_invulnerability_on_off(self):
        enemy = self.game.create_unit(1, rawcode("N002"))
        self.hero.abilities.add(rawcode("Avul"))
        self.activate()
        self.game.command("-whosyourdaddy")
        self.assertIn(rawcode("ATwd"), self.hero.abilities)
        self.game.damage(self.hero, enemy, 1.0)
        self.assertLessEqual(enemy.life, 0)
        self.game.command("-whosyourdaddy")
        self.assertNotIn(rawcode("ATwd"), self.hero.abilities)
        self.assertIn(rawcode("Avul"), self.hero.abilities)

    def test_god_mode_applies_to_new_units_and_removes_on_owner_change(self):
        self.activate()
        self.game.command("-whosyourdaddy")
        summon = self.game.create_unit(0, rawcode("hfoo"))
        self.assertIn(rawcode("ATwd"), summon.abilities)
        life = summon.life
        self.game.damage(self.game.create_unit(1, rawcode("hfoo")), summon, 500)
        self.assertEqual(life, summon.life)
        summon.owner = 1
        self.tick()
        self.assertNotIn(rawcode("ATwd"), summon.abilities)

    def test_normal_repick_conditions_are_preserved(self):
        self.assertTrue(self.game.g["hBx"]())
        self.assertTrue(self.game.g["Hlx"]())
        self.game.g["y4"][1] = True
        self.assertFalse(self.game.g["hBx"]())
        self.assertFalse(self.game.g["Hlx"]())

    def test_cheat_repick_routes_away_from_normal_handlers(self):
        self.activate()
        self.assertFalse(self.game.g["hBx"]())
        self.assertFalse(self.game.g["Hlx"]())

    def test_late_repick_keeps_items_and_duel_state_and_can_repeat(self):
        self.activate()
        self.game.g["y4"][1] = True  # Original one-use limit already consumed.
        self.game.g["i4"] = set()  # Original hero pool destroyed at game start.
        self.hero.items[0] = {"type": "potion", "charges": 17}
        saved_item = self.hero.items[0]
        self.hero.paused = True
        self.game.g["x"] = self.hero
        self.tick()
        self.game.command("-repick")
        dialog = self.game.g["TestCommands_RepickDialog"][0]
        self.assertTrue(dialog["visible"])
        self.game.clicked = dialog["buttons"][0][0]
        self.game.g["TestCommands_RepickClick"]()
        replacement = self.game.g["m"][1]
        self.assertIsNot(replacement, self.hero)
        self.assertIs(replacement.items[0], saved_item)
        self.assertEqual(replacement.items[0]["charges"], 17)
        self.assertEqual((replacement.x, replacement.y), (100.0, 200.0))
        self.assertTrue(replacement.paused)
        self.assertIs(self.game.g["x"], replacement)
        self.assertEqual(self.game.gold[0], 700)
        self.game.command("-repick")
        self.assertTrue(dialog["visible"])

    def test_repick_cancel_and_insufficient_gold_preserve_hero(self):
        self.activate()
        self.game.command("-repick")
        dialog = self.game.g["TestCommands_RepickDialog"][0]
        self.game.clicked = dialog["buttons"][-1][0]
        self.game.g["TestCommands_RepickClick"]()
        self.assertIs(self.game.g["m"][1], self.hero)
        self.assertEqual(self.game.gold[0], 1000)
        self.game.gold[0] = 299
        self.game.command("-repick")
        self.assertFalse(dialog["visible"])
        self.assertIs(self.game.g["m"][1], self.hero)

    def test_existing_commands_keep_access_and_argument_checks(self):
        self.game.command("-gold 50")
        self.assertEqual(self.game.gold[0], 1000)
        self.activate()
        self.game.command("-gold 50")
        self.assertEqual(self.game.gold[0], 1050)
        self.game.command("-gold 050")
        self.assertEqual(self.game.gold[0], 1050)
        self.game.command("-level 20")
        self.assertEqual(self.hero.level, 20)


if __name__ == "__main__":
    unittest.main()
