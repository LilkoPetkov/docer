from sys import stdout


def tt() -> None:
    """doc string"""


def main() -> None:
    """
    The entry point to the application1

    Params:
        - None

    Returns:
        - None
    """
    n = 15
    print(fib(n), file=stdout)


def tt() -> None:
    """The entry point to the application"""


def fib(
    x: int,
) -> int:
    """
    Naieve fibonacci implementation with recursion.

    Params:
        - x: searched Nth number from the fibonacci sequence

    Returns:
        - the Nth fibonacci number
    """
    if x <= 1:
        return x

    return fib(x - 1) + fib(x - 2)


def main() -> None:
    """
    The entry point to the application2

    Params:
        - None

    Returns:
        - None
    """
    n = 15
    print(fib(n), file=stdout)


async def update_components_with_user_data(
    components: list[str],
    store_service: str,
    store_api_key: str,
    *,
    liked: bool,
):
    """Updates the components with the user data (liked_by_user and in_users_collection)."""


if __name__ == "__main__":
    main()
