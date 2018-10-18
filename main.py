import hashlib
from Hack import Hack
import string

chars = "@_!#$%^&*()<>?~:" + string.ascii_letters + string.digits


def main():
    print("Insert password: ")
    password = input()
    first = hashlib.sha1(b'(%s)' % str.encode(password))
    hash = first.hexdigest()
    print("First hash: ")
    print(hash)
    obj = Hack(chars)
    result = obj.find_pass(hash)
    print("Your password:")
    print(result)


if __name__ == '__main__':
    main()
