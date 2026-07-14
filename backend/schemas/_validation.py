from typing import Annotated

from pydantic import Field


Phone = Annotated[
    str,
    Field(pattern=r"^0\d{9}$"),
]

Pin = Annotated[
    str,
    Field(pattern=r"^\d{6}$"),
]

Password = Annotated[
    str,
    Field(min_length=6, max_length=64),
]
