#!/usr/bin/env python3

# SPDX-License-Identifier: {{ cookiecutter.license }}

import sys
{% for DEP in cookiecutter.dependencies.default %}
import {{ DEP }}
{%- endfor %}

from typing import Optional


def main() -> Optional[int]:
    print('Hello, World!')

if __name__ == "__main__":
    sys.exit(main())
