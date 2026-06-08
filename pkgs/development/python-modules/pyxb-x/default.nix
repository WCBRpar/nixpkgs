# pkgs/development/python-modules/pyxb/package.nix

{ lib
, buildPythonPackage
, fetchFromGitHub
, setuptools
, six
}:

buildPythonPackage rec {
  pname = "pyxb-x";
  version = "1.2.6.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "renalreg";
    repo = "PyXB-X";
    rev = "v${version}";
    hash = "sha256-Pn6REZ+aE2Qlrczb2oyAagyFOa4ijR+hB+02O2SFSoA=";
  };

  build-system = [ setuptools ];

  buildInputs = [ six ];
  propagatedBuildInputs = [ six ];

  postPatch = ''
    # Remove o six interno
    rm -f pyxb/utils/six.py

    # Cria proxy completo para six (adiciona atributos *type que o PyXB espera)
    cat > pyxb/utils/six.py <<EOF
from six import *
import six as _six

# Mapeamentos de tipos que o PyXB espera (não existem no six moderno)
int_type = int
long_type = int
float_type = float
list_type = list
tuple_type = tuple
dict_type = dict
str_type = str
unicode_type = str
bytes_type = bytes
bytearray_type = bytearray
bool_type = bool
object_type = object
type_type = type
complex_type = complex
NoneType = type(None)

# Mantém os que já existem
text_type = _six.text_type
binary_type = _six.binary_type
EOF

    # Substitui imports de pyxb.utils.six.moves por six.moves
    find . -type f -name "*.py" -exec sed -i 's/from pyxb\.utils\.six\.moves/from six.moves/g' {} \;

    # Corrige imports de ABCs do collections (Python 3.10+)
    find . -type f -name "*.py" -exec sed -i 's/collections\.MutableSequence/collections.abc.MutableSequence/g' {} \;
    find . -type f -name "*.py" -exec sed -i 's/collections\.MutableMapping/collections.abc.MutableMapping/g' {} \;
    find . -type f -name "*.py" -exec sed -i 's/collections\.Sequence/collections.abc.Sequence/g' {} \;
    find . -type f -name "*.py" -exec sed -i 's/collections\.Iterable/collections.abc.Iterable/g' {} \;
    find . -type f -name "*.py" -exec sed -i 's/collections\.Iterator/collections.abc.Iterator/g' {} \;
    find . -type f -name "*.py" -exec sed -i 's/collections\.Callable/collections.abc.Callable/g' {} \;
    find . -type f -name "*.py" -exec sed -i 's/from collections import MutableSequence/from collections.abc import MutableSequence/g' {} \;
    find . -type f -name "*.py" -exec sed -i 's/from collections import Sequence/from collections.abc import Sequence/g' {} \;
    find . -type f -name "*.py" -exec sed -i 's/from collections import MutableMapping/from collections.abc import MutableMapping/g' {} \;
    find . -type f -name "*.py" -exec sed -i 's/from collections import Iterable/from collections.abc import Iterable/g' {} \;
    find . -type f -name "*.py" -exec sed -i 's/from collections import Iterator/from collections.abc import Iterator/g' {} \;
  '';

  doCheck = false;

  pythonImportsCheck = [
    "pyxb"
    "pyxb.binding"
  ];

  meta = with lib; {
    description = "PyXB: Python XML Schema Bindings - Generates Python code from XML Schema";
    longDescription = ''
      PyXB is a pure Python package that generates Python source code for
      classes that correspond to data structures defined by XML Schema.
      It's used by the Brazilian ERP community for XML fiscal document handling.
    '';
    homepage = "https://github.com/renalreg/pyxb-x";
    changelog = "https://github.com/renalreg/pyxb-x/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ wjjunyor ];
  };
}
