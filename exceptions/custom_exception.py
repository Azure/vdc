class CustomException(Exception):
    _message = ''
    def __init__(self, message):

        self._message = message
        # Call the base class constructor with the parameters it needs
        super().__init__(message)

