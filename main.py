import hashlib
import string

from Hack import Hack

chars = "@_!#$%^&*()<>?~:" + string.ascii_letters + string.digits

def main():
    print("Insert password: ")
    password = input()
    hash = hashlib.sha1(b'(%s)' % str.encode(password)).hexdigest()
    print("Hashed password: {}".format(hash))
    obj = Hack(chars)
    result = obj.find_pass(hash)
    print("Your password: {}".format(result))


if __name__ == '__main__':
    main()
