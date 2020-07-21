from py.static.Role import Role
from abc import ABC, abstractmethod


class PlayerClass(ABC):

    @property
    @abstractmethod
    def specs(self):
        pass

    @property
    @abstractmethod
    def spec_roles(self):  # todo test if this works
        pass

    def get_spec_name_from_idx(self, idx):
        return [k for k, v in self.specs.items() if v == idx][0]

    def get_role_for_spec(self, spec_name):
        return self.spec_roles[spec_name]


class Priest(PlayerClass):
    name = "Priest"
    wcl_id = 7
    specs = {
        "Discipline": 1,
        "Holy": 2,
        "Shadow": 3,
    }
    spec_roles = {
        "Discipline": Role.HPS,
        "Holy": Role.HPS,
        "Shadow": Role.DPS,
    }  # todo maybe generate lua role lookups (for recount query) based on this


class Druid(PlayerClass):
    name = "Druid"
    wcl_id = 2
    specs = {
        "Balance": 1,
        "Feral": 2,
        "Guardian": 3,
        "Restoration": 0  # Documentation says 4, but this appears to work (4 doesnt)
    }
    spec_roles = {
        "Balance": Role.DPS,
        "Feral": Role.DPS,
        "Guardian": Role.DPS,
        "Restoration": Role.HPS
    }


class Shaman(PlayerClass):
    name = "Shaman"
    wcl_id = 9
    specs = {
        "Elemental": 1,
        "Enhancement": 2,
        "Restoration": 3
    }
    spec_roles = {
        "Elemental": Role.DPS,
        "Enhancement": Role.DPS,
        "Restoration": Role.HPS
    }


class Mage(PlayerClass):
    wcl_id = 4
    name = "Mage"
    specs = {
        "Arcane": 1,
        "Fire": 2,
        "Frost": 3,
    }
    spec_roles = {
        "Arcane": Role.DPS,
        "Fire": Role.DPS,
        "Frost": Role.DPS,
    }
