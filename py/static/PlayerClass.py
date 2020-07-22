from py.static.Role import Role
from abc import ABC, abstractmethod


class PlayerClass(ABC):

    @property
    @abstractmethod
    def specs(self):
        pass

    @property
    @abstractmethod
    def spec_roles(self):
        pass

    @property
    @abstractmethod
    def name(self):
        pass

    def get_spec_name_from_idx(self, idx):
        return [k for k, v in self.specs.items() if v == idx][0]

    def get_role_for_spec(self, spec_name):
        return self.spec_roles[spec_name]

    def generate_lua_rolemap_string(self):
        lua_str = "[\"" + self.name + "\"] = { \n"
        for spec, role in self.spec_roles.items():
            full_role = "healer" if role == Role.HPS else "damage"
            lua_str += "    [\"" + spec + "\"] = \"" + full_role + "\",\n"
        lua_str += "},"
        return lua_str


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
    }


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


class Monk(PlayerClass):
    name = "Monk"
    wcl_id = 5
    specs = {
        "Brewmaster": 1,
        "Mistweaver": 2,
        "Windwalker": 3
    }
    spec_roles = {
        "Brewmaster": Role.DPS,
        "Mistweaver": Role.HPS,
        "Windwalker": Role.DPS
    }


class Paladin(PlayerClass):
    name = "Paladin"
    wcl_id = 6
    specs = {
        "Holy": 1,
        "Protection": 2,
        "Retribution": 3
    }
    spec_roles = {
        "Holy": Role.HPS,
        "Protection": Role.DPS,
        "Retribution": Role.DPS
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


if __name__ == '__main__':
    classes = [Priest(), Monk(), Shaman(), Paladin(), Druid(), Mage()]  # todo
    for player_class in classes:
        print(player_class.generate_lua_rolemap_string())