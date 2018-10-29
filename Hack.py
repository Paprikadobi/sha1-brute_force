import hashlib
from itertools import chain, product


class Hack:

    def __init__(self, chars):
        self.chars = chars

    def bruteforce(self, charset, min_length, max_length):
        return (''.join(candidate)
            for candidate in chain.from_iterable(product(charset, repeat = i)
            for i in range(min_length, max_length + 1)))

    def find_pass(self, hash):
        while True:
            for password in self.bruteforce(self.chars, 4, 4):
                hash1 = hashlib.sha1(b'(%s)' % str.encode(password)).hexdigest()
                if hash1 == hash:
                    return password