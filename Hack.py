import hashlib
from itertools import chain, product


class Hack:

    def __init__(self, chars):
        self.chars = chars

    def bruteforce(self, charset, maxlength):
        return (''.join(candidate)
            for candidate in chain.from_iterable(product(charset, repeat=i)
            for i in range(3, maxlength + 1)))

    def find_pass(self, hash):
        while True:
            n = 4
            for (i, a) in enumerate(self.bruteforce(self.chars, n)):
                hash1 = hashlib.sha1(b'(%s)' % str.encode(a)).hexdigest()
                print(a + "   " + hash1)
                if hash1 == hash:
                    return a
                n = n + 1