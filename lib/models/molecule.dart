import 'package:vector_math/vector_math.dart';

class Atom {
  final String element;
  final Vector3 position;

  Atom({required this.element, required this.position});
}

class Bond {
  final int atomIndex1;
  final int atomIndex2;

  Bond({required this.atomIndex1, required this.atomIndex2});
}

class Molecule {
  final List<Atom> atoms;
  final List<Bond> bonds;

  Molecule({required this.atoms, required this.bonds});
}
