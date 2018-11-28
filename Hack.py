from sha1 import sha1
from itertools import chain, product


class Hack:
    def __init__(self, chars):
        self.chars = chars

    def bruteforce(self, charset, min_length, max_length):
        return (''.join(candidate)
            for candidate in chain.from_iterable(product(charset, repeat = i)
            for i in range(min_length, max_length + 1)))

    def find_pass(self, hash):
        for password in self.bruteforce(self.chars, 1, 7):
            if sha1(password.encode()) == hash:
                return password.encode()