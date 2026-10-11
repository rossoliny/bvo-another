"""Execute the map's JASS scoreboard with deterministic Warcraft fixtures."""
from collections import defaultdict
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "cheats/tests"))
from test_commands import Game, Unit, rawcode


class ScoreboardGame:
    compile = Game.compile

    def __init__(self):
        self.g = {"__builtins__": __builtins__}
        self.cells, self.styles, self.icons, self.quests = {}, {}, {}, []
        self.names = defaultdict(lambda: "Player")
        self.names.update({0: "Red", 2: "Teal", 7: "Pink"})
        self.slots = defaultdict(lambda: "EMPTY", {0: "PLAYING", 2: "PLAYING", 7: "PLAYING"})
        self.gold = defaultdict(int, {0: 1000, 2: 1000, 7: 1000})
        self.local_player = 0
        self.dying = None
        self.initializing = False
        self.timers = []
        self.expired_timer = None
        self.triggering_trigger = None
        text = (ROOT / "Current Script/war3map.j").read_text(encoding="utf-8")
        for kind, array, name, initial in re.findall(
                r"^\s*(\w+)\s+(array\s+)?(\w+)(?:\s*=\s*([^\n]+))?$",
                text.split("endglobals", 1)[0], re.M):
            default = False if kind == "boolean" else 0 if kind in ("integer", "real") else None
            value = defaultdict(lambda default=default: default) if array else default
            if initial and kind == "string":
                value = initial.strip().strip('"')
            self.g[name] = value
        self.g.update({
            "e": {0, 2}, "f": {7}, "h": 7, "j": 3, "k": 90,
            "PLAYER_SLOT_STATE_PLAYING": "PLAYING", "PLAYER_SLOT_STATE_LEFT": "LEFT",
            "PLAYER_STATE_RESOURCE_GOLD": "GOLD", "UNIT_TYPE_HERO": "HERO",
            "bj_lastCreatedMultiboard": None, "bj_lastCreatedQuest": None,
            "Player": lambda player: player, "GetPlayerId": lambda player: player,
            "GetPlayerName": lambda player: self.names[player],
            "GetPlayerSlotState": lambda player: self.slots[player],
            "GetLocalPlayer": lambda: self.local_player,
            "IsPlayerInForce": lambda player, force: player in force,
            "GetPlayerState": lambda player, state: self.gold[player],
            "GetHeroLevel": lambda hero: hero.level if hero else 0,
            "GetUnitTypeId": lambda hero: hero.kind if hero else 0,
            "GetOwningPlayer": lambda hero: hero.owner,
            "GetTriggerUnit": lambda: self.dying,
            "IsUnitType": lambda hero, kind: bool(hero and hero.kind),
            "IsUnitIllusion": lambda hero: getattr(hero, "illusion", False),
            "I2S": lambda value: str(int(value)), "R2I": int, "I2R": float,
            "StringLength": len, "SubString": lambda text, start, end: text[start:end],
            "ModuloInteger": lambda dividend, divisor: dividend % divisor,
            "GetBooleanOr": lambda left, right: left or right,
            "EVENT_PLAYER_UNIT_DEATH": "DEATH",
            "CreateTrigger": lambda: {},
            "TriggerRegisterAnyUnitEventBJ": lambda *args: None,
            "TriggerAddAction": lambda trigger, action: trigger.update(action=action),
            "CreateTimer": self.create_timer,
            "TimerStart": lambda timer, timeout, periodic, action: timer.update(
                timeout=timeout, periodic=periodic, action=action),
            "GetExpiredTimer": lambda: self.expired_timer,
            "DestroyTimer": lambda timer: timer.update(destroyed=True) if timer else None,
            "CreateMultiboardBJ": self.create_board,
            "MultiboardGetItem": lambda board, row, col: (row + 1, col + 1),
            "MultiboardSetItemValue": lambda cell, value: self.cells.__setitem__(cell, value),
            "MultiboardSetItemStyle": lambda cell, value, icon: self.styles.__setitem__(cell, (value, icon)),
            "MultiboardSetItemIcon": lambda cell, icon: self.icons.__setitem__(cell, icon),
            "MultiboardSetItemWidth": lambda *args: None,
            "MultiboardReleaseItem": lambda *args: None,
            "MultiboardSetItemsValueColor": lambda *args: None,
            "MultiboardSetTitleText": lambda board, title: board.update(title=title),
            "MultiboardDisplay": lambda *args: None, "MultiboardMinimize": lambda *args: None,
            "EnableTrigger": lambda *args: None, "TriggerExecute": lambda *args: None,
            "GetTriggeringTrigger": lambda: self.triggering_trigger,
            "DestroyTrigger": lambda trigger: trigger.update(destroyed=True) if trigger else None,
            "TriggerSleepAction": lambda *args: None,
            "CreateQuestBJ": lambda kind, title, description, icon: self.quests.append((title, description)),
            "QuestSetEnabled": lambda *args: None,
        })
        self.g["m"][1] = Unit(0, level=4)
        self.g["m"][3] = Unit(2, level=6)
        self.g["m"][8] = Unit(7, level=9, kind=rawcode("H01Q"))
        self.g["d"].update({1: 2, 3: 5, 8: 3})
        self.g["Scoreboard_Deaths"].update({1: 1, 3: 2, 8: 4})
        for name, parameters, result, body in re.findall(
                r"^function (\w+) takes (.*?) returns (\w+)\n(.*?)^endfunction", text, re.M | re.S):
            if name.startswith("Scoreboard_") or name in ("MapIdentity_IsUnexpected", "MapInfo_CreateQuests"):
                self.compile(name, parameters, body)

    def create_board(self, columns, rows, title):
        board = {"columns": columns, "rows": rows, "title": title,
                 "displayed": not self.initializing}
        self.g["bj_lastCreatedMultiboard"] = board
        return board

    def create_timer(self):
        timer = {}
        self.timers.append(timer)
        return timer


class ScoreboardTests(unittest.TestCase):
    def setUp(self):
        self.game = ScoreboardGame()

    def create(self):
        self.assertTrue("Scoreboard_Create" in self.game.g, "The 1.1c scoreboard has not been implemented")
        self.game.g["Scoreboard_Create"]()

    def test_startup_defers_board_until_it_can_be_displayed(self):
        self.game.initializing = True
        self.game.g["Scoreboard_Init"]()
        self.game.triggering_trigger = self.game.g["Scoreboard_CreateTrigger"]
        self.game.triggering_trigger["action"]()
        self.assertIsNone(self.game.g["Scoreboard"],
                          "Warcraft cannot display a board created during map initialization")
        self.game.initializing = False
        self.game.triggering_trigger = None
        for timer in list(self.game.timers):
            if not timer["periodic"]:
                self.game.expired_timer = timer
                timer["action"]()
                self.assertTrue(timer.get("destroyed"), "The creation timer must be released")
        self.assertTrue(self.game.g["Scoreboard"]["displayed"])
        self.assertEqual(self.game.cells[(5, 2)], "|c00FF00002|r")
        self.assertEqual(self.game.cells[(10, 3)], "|c007EBFF14|r")
        self.game.g["Scoreboard_Timer"]["action"]()
        self.assertIn("Time: |c0000ffff00:00:01|r", self.game.g["Scoreboard"]["title"])

    def test_rows_follow_actual_team_members_with_empty_slots(self):
        self.create()
        board = self.game.g["Scoreboard"]
        self.assertEqual((board["columns"], board["rows"]), (5, 10))
        self.assertEqual([self.game.g["Scoreboard_PlayerRows"][index] for index in (1, 3, 8)], [5, 6, 10])
        self.assertEqual(self.game.g["Scoreboard_PlayerRows"][2], 0)
        self.assertEqual(self.game.styles[(2, 1)], (False, False))
        self.assertEqual(self.game.icons[(10, 1)], "ReplaceableTextures\\CommandButtons\\BTNrenji.blp")

    def test_levels_deaths_and_team_totals_use_registered_heroes(self):
        self.create()
        self.game.g["Scoreboard_Update"]()
        self.assertEqual(self.game.cells[(5, 4)], "|c0000FFFF4|r")
        self.assertEqual(self.game.cells[(3, 3)], "|c007EBFF13|r")
        self.assertEqual(self.game.cells[(3, 4)], "|c0000FFFF10|r")
        self.assertEqual(self.game.cells[(8, 4)], "|c0000FFFF9|r")
        self.assertIn("Win = |c0000ffff90|r", self.game.g["Scoreboard"]["title"])

    def test_clock_rolls_over_minutes_and_hours_without_changing_identity(self):
        self.create()
        self.game.g["Scoreboard_ElapsedSeconds"] = 3599
        self.game.g["Scoreboard_Tick"]()
        self.assertIn("Time: |c0000ffff01:00:00|r", self.game.g["Scoreboard"]["title"])
        self.assertFalse(self.game.g["MapIdentity_IsUnexpected"]())
        self.game.g["Scoreboard_ElapsedSeconds"] = 59
        self.game.g["Scoreboard_Tick"]()
        self.assertIn("Time: |c0000ffff00:01:00|r", self.game.g["Scoreboard"]["title"])

    def test_gold_spending_is_not_counted_as_income_and_enemy_total_is_hidden(self):
        self.create()
        self.game.g["Scoreboard_ElapsedSeconds"] = 60
        self.game.gold[0] = 600
        self.game.g["Scoreboard_Tick"]()
        self.game.gold[0] = 750
        self.game.g["Scoreboard_Tick"]()
        self.assertEqual(self.game.g["Scoreboard_GoldEarned"][1], 150)
        self.assertEqual(self.game.cells[(3, 5)], "|c00FFD700145|r")
        self.assertEqual(self.game.cells[(8, 5)], "")

    def test_hero_deaths_use_new_row_and_ignore_illusions(self):
        self.create()
        self.game.dying = Unit(7, kind=rawcode("H01F"))
        self.game.g["Scoreboard_Death"]()
        self.assertEqual(self.game.g["Scoreboard_Deaths"][8], 4)
        self.game.dying = self.game.g["m"][8]
        self.game.g["Scoreboard_Death"]()
        self.assertEqual(self.game.g["Scoreboard_Deaths"][8], 5)
        self.assertEqual(self.game.cells[(10, 3)], "|c007EBFF15|r")
        self.game.dying.illusion = True
        self.game.g["Scoreboard_Death"]()
        self.assertEqual(self.game.g["Scoreboard_Deaths"][8], 5)

    def test_departed_player_keeps_row_stats_and_stops_accumulating_gold(self):
        self.create()
        self.game.slots[7] = "LEFT"
        self.game.g["m"][8].kind = 0
        self.game.gold[7] = 5000
        self.game.g["Scoreboard_Tick"]()
        self.assertEqual(self.game.cells[(10, 1)], "|c00708090Pink|r")
        self.assertEqual(self.game.cells[(10, 4)], "|c0000FFFF9|r")
        self.assertEqual(self.game.g["Scoreboard_GoldEarned"][8], 0)

    def test_info_sections_resolve_to_nonempty_text_without_wts(self):
        self.assertTrue("MapInfo_CreateQuests" in self.game.g, "INFO still depends on the missing WTS")
        self.game.g["MapInfo_CreateQuests"]()
        self.assertEqual(len(self.game.quests), 8)
        for title, description in self.game.quests:
            self.assertTrue(description.strip(), title)
            self.assertFalse(description.startswith("TRIGSTR_"), title)
        self.assertIn("BvO Another v1.1a Rossoliny", dict(self.game.quests)["Author Comments"])


if __name__ == "__main__":
    unittest.main()
