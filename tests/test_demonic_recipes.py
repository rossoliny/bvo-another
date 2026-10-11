"""Run the real recipe handlers against six-slot Warcraft inventory fixtures."""
from dataclasses import dataclass, field
import os
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "cheats/tests"))
from test_commands import Game, rawcode


def read_item_data(path):
    cells = {}
    row = column = 1
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("C;"):
            continue
        row_match = re.search(r";Y(\d+)", line)
        column_match = re.search(r";X(\d+)", line)
        if row_match:
            row = int(row_match[1])
        if column_match:
            column = int(column_match[1])
        value_match = re.search(r";K(.*)", line)
        if value_match:
            cells.setdefault(row, {})[column] = value_match[1].strip('"')
    return {values[1]: {cells[1][index]: value for index, value in values.items()}
            for row, values in cells.items() if row != 1}


@dataclass(eq=False)
class Item:
    kind: int


@dataclass
class Buyer:
    items: list = field(default_factory=lambda: [None] * 6)
    hero: bool = True
    gold: int = 50000


class RecipeGame:
    def __init__(self):
        script_path = Path(os.environ.get("BVO_RECIPE_SCRIPT", ROOT / "Current Script/war3map.j"))
        data_path = Path(os.environ.get("BVO_RECIPE_DATA", ROOT / "SLKs/ItemData.slk"))
        self.data = read_item_data(data_path)
        self.buyer = Buyer()
        self.triggers = []
        self.dropped = []
        self.manipulated = self.sold = None
        self.g = {
            "__builtins__": __builtins__,
            "EVENT_PLAYER_UNIT_PICKUP_ITEM": "pickup",
            "EVENT_PLAYER_UNIT_SELL_ITEM": "sale",
            "UNIT_TYPE_HERO": "hero",
            "GetTriggerUnit": lambda: self.buyer,
            "GetBuyingUnit": lambda: self.buyer,
            "GetManipulatedItem": lambda: self.manipulated,
            "GetSoldItem": lambda: self.sold,
            "GetItemTypeId": lambda item: item.kind if item else 0,
            "IsUnitType": lambda unit, kind: unit.hero and kind == "hero",
            "UnitHasItemOfTypeBJ": lambda unit, kind: self.find_item(unit, kind) is not None,
            "GetItemOfTypeFromUnitBJ": self.find_item,
            "RemoveItem": self.remove_item,
            "UnitAddItemByIdSwapped": self.add_item,
            "CreateTrigger": self.create_trigger,
            "TriggerRegisterAnyUnitEventBJ": lambda trigger, event: trigger.update(event=event),
            "TriggerAddCondition": lambda trigger, condition: trigger["conditions"].append(condition),
            "TriggerAddAction": lambda trigger, action: trigger["actions"].append(action),
            "Condition": lambda callback: callback,
            "AddSpecialEffectTargetUnitBJ": lambda *args: None,
            "DestroyEffect": lambda *args: None,
            "DestroyEffectBJ": lambda *args: None,
            "GetLastCreatedEffectBJ": lambda: None,
            "bj_lastCreatedEffect": None,
            "DoNothing": lambda: None,
        }
        for name, parameters, body in re.findall(
                r"^function (\w+) takes (.*?) returns \w+\n(.*?)^endfunction",
                script_path.read_text(encoding="utf-8"), re.M | re.S):
            if name.startswith(("Trig_Demonic", "DemonicArmor", "DemonicBoots", "InitTrig_Demonic")):
                Game.compile(self, name, parameters, body)
        self.g["InitTrig_Demonic_Armor"]()
        self.g["InitTrig_DemonicBoot"]()

    def create_trigger(self):
        trigger = {"conditions": [], "actions": []}
        self.triggers.append(trigger)
        return trigger

    def dispatch(self, event):
        for trigger in self.triggers:
            if trigger["event"] == event and all(condition() for condition in trigger["conditions"]):
                for action in trigger["actions"]:
                    action()

    def find_item(self, unit, kind):
        return next((item for item in unit.items if item and item.kind == kind), None)

    def remove_item(self, item):
        if item in self.buyer.items and item is not None:
            self.buyer.items[self.buyer.items.index(item)] = None
        if item in self.dropped:
            self.dropped.remove(item)

    def add_item(self, kind, unit):
        item = Item(kind)
        if None in unit.items:
            unit.items[unit.items.index(None)] = item
            previous = self.manipulated
            self.manipulated = item
            self.dispatch("pickup")
            self.manipulated = previous
        else:
            self.dropped.append(item)
        return item

    def inventory(self):
        return [item.kind for item in self.buyer.items if item]

    def seed_inventory(self, names):
        self.buyer.items = [Item(rawcode(name)) for name in names] + [None] * (6 - len(names))

    def purchase(self, name):
        data = self.data[name]
        powerup = data.get("powerup", "0") == "1"
        if not powerup and None not in self.buyer.items:
            return False
        self.buyer.gold -= int(data["goldcost"])
        self.sold = Item(rawcode(name))
        if powerup:
            self.manipulated = self.sold
            self.dispatch("pickup")
            self.manipulated = None
            if not (data.get("usable") == "1" and data.get("perishable") == "1"
                    and data.get("uses") == "1" and data.get("abilList") == "A066"):
                self.dropped.append(self.sold)
        else:
            self.add_item(self.sold.kind, self.buyer)
        self.dispatch("sale")
        return True


class DemonicRecipeTests(unittest.TestCase):
    CASES = [
        ("I080", ["I086", "I04M"], "I084", "I083", 9000),
        ("I05C", ["I00C"], "I05B", "I087", 3300),
    ]
    FILLERS = ["I000", "I015", "I039", "I017", "I006", "I00V"]

    def test_purchase_with_all_six_slots_occupied_consumes_only_components(self):
        for shop, components, result, recipe, cost in self.CASES:
            with self.subTest(shop=shop):
                game = RecipeGame()
                fillers = self.FILLERS[:6 - len(components)]
                game.seed_inventory(components + fillers)
                self.assertTrue(game.purchase(shop), "Recipe purchase must accept a full inventory")
                self.assertCountEqual(game.inventory(), [rawcode(name) for name in fillers + [result]])
                self.assertEqual(game.dropped, [])
                self.assertEqual(game.buyer.gold, 50000 - cost)

    def test_purchase_with_free_slots_crafts_once(self):
        for shop, components, result, recipe, cost in self.CASES:
            with self.subTest(shop=shop):
                game = RecipeGame()
                game.seed_inventory(components)
                self.assertTrue(game.purchase(shop))
                self.assertEqual(game.inventory(), [rawcode(result)])
                self.assertEqual(game.dropped, [])

    def test_purchase_without_components_keeps_a_recipe(self):
        for shop, components, result, recipe, cost in self.CASES:
            with self.subTest(shop=shop):
                game = RecipeGame()
                self.assertTrue(game.purchase(shop))
                self.assertEqual(game.inventory(), [rawcode(recipe)])
                self.assertEqual(game.dropped, [])
                self.assertEqual(game.buyer.gold, 50000 - cost)

    def test_full_inventory_without_components_drops_only_the_recipe(self):
        for shop, components, result, recipe, cost in self.CASES:
            with self.subTest(shop=shop):
                game = RecipeGame()
                game.seed_inventory(self.FILLERS)
                self.assertTrue(game.purchase(shop))
                self.assertEqual(game.inventory(), [rawcode(name) for name in self.FILLERS])
                self.assertEqual([item.kind for item in game.dropped], [rawcode(recipe)])
                self.assertEqual(game.buyer.gold, 50000 - cost)

    def test_bought_recipe_can_be_completed_later(self):
        for shop, components, result, recipe, cost in self.CASES:
            with self.subTest(shop=shop):
                game = RecipeGame()
                game.purchase(shop)
                for component in components:
                    game.add_item(rawcode(component), game.buyer)
                self.assertEqual(game.inventory(), [rawcode(result)])
                self.assertEqual(game.buyer.gold, 50000 - cost)

    def test_picking_up_recipe_with_components_crafts_once(self):
        for shop, components, result, recipe, cost in self.CASES:
            with self.subTest(shop=shop):
                game = RecipeGame()
                game.seed_inventory(components)
                game.add_item(rawcode(recipe), game.buyer)
                self.assertEqual(game.inventory(), [rawcode(result)])
                self.assertEqual(game.buyer.gold, 50000)

    def test_partial_armor_components_are_preserved(self):
        for component in ["I086", "I04M"]:
            with self.subTest(component=component):
                game = RecipeGame()
                game.seed_inventory([component])
                game.purchase("I080")
                self.assertCountEqual(game.inventory(), [rawcode(component), rawcode("I083")])

    def test_other_shop_items_do_not_consume_demonic_components(self):
        game = RecipeGame()
        game.seed_inventory(["I086", "I04M", "I00C"])
        game.purchase("I03Q")
        self.assertCountEqual(game.inventory(), [rawcode("I086"), rawcode("I04M"), rawcode("I00C")])

    def test_disabled_armor_icon_is_available_at_the_engine_lookup_path(self):
        resources = Path(os.environ.get("BVO_RECIPE_RESOURCES", ROOT))
        icon = resources / "ReplaceableTextures/CommandButtonsDisabled/DISBTNDemonA.blp"
        self.assertEqual(icon.read_bytes(),
                         (ROOT / "ReplaceableTextures/CommandButtonsDisabled/DISBTNDemonA.blp").read_bytes())


if __name__ == "__main__":
    unittest.main()
