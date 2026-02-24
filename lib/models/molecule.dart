class Atom {
  final String element;
  final double x;
  final double y;
  final double z;
  final int index;

  Atom({
    required this.element,
    required this.x,
    required this.y,
    required this.z,
    required this.index,
  });

  Map<String, dynamic> toJson() {
    return {'element': element, 'x': x, 'y': y, 'z': z, 'index': index};
  }
}

class Bond {
  final int atomIndex1;
  final int atomIndex2;

  Bond({required this.atomIndex1, required this.atomIndex2});

  Map<String, dynamic> toJson() {
    return {'atom1': atomIndex1, 'atom2': atomIndex2};
  }
}

class Molecule {
  final List<Atom> atoms;
  final List<Bond> bonds;

  Molecule({required this.atoms, required this.bonds});

  Map<String, dynamic> toJson() {
    return {
      'atoms': atoms.map((a) => a.toJson()).toList(),
      'bonds': bonds.map((b) => b.toJson()).toList(),
    };
  }
}
