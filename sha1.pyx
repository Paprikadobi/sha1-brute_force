# distutils: extra_compile_args = -fopenmp
# distutils: extra_link_args = -fopenmp
# cython: nonecheck = False, wraparound = False, boundscheck = False, cdivision = True

from libc.string cimport strlen
from libc.stdlib cimport malloc, free
from libc.math cimport pow

from cython.parallel cimport parallel

# pomocná struktura, která uchovává délku a informaci o tom, od jakého písmena se má pokračovat pro každé vlákno
cdef struct holder_t:
    unsigned int length, offset

# pomocná struktura pro uchování heše
cdef struct hash_t:
    unsigned int h0, h1, h2, h3, h4

cdef class Generator:

    cdef char* charset # všechny možné znaky, které může heslo obsahovat
    cdef unsigned int charset_length # počet možných znaků
    cdef unsigned long i # určuje pořadí příštího hesla
    cdef unsigned int length # určuje aktuální délku slova
    cdef unsigned int max_length # určuje maximální délku slova
    cdef char* password # uchovává nalezené heslo
    cdef char found # informace pro ostatní vlákna o nalezení hesla
    cdef unsigned long* steps # určuje hodnoty 'i', při kterých se mění délka generovaných hesel
    cdef unsigned int buff_size # určuje kolik hesel se generuje při zavolání funkce 'next'
    cdef char* pattern

    def __cinit__(self, const char[] charset, int min_length, int max_length, unsigned int buff_size):
        self.charset = charset
        self.charset_length = strlen(charset)
        self.length = min_length
        self.buff_size = buff_size
        self.max_length = max_length
        self.password = NULL
        self.found = 0

        cdef int j
        self.steps = <unsigned long*>malloc(sizeof(unsigned long) * (max_length + 2))
        self.steps[0] = 0
        for j in range(1, max_length + 1):
            self.steps[j] = self.steps[j - 1] + <unsigned long>pow(self.charset_length, j)

        self.i = self.steps[min_length - 1]

    cdef void next(self, unsigned int* w, holder_t* holder) nogil:
        cdef unsigned long j = self.i
        self.i += self.buff_size
        
        cdef unsigned int i, k, l

        cdef unsigned int length = self.length

        # pokud jsme prošli všechny kombinace pro danou délku hesla, tak ji zvýšíme
        # pokud je nová délka hesla větší než nastavená maximální délka, tak skončíme
        if j == self.steps[self.length]:
            self.length += 1
            length = length + 1
            if self.length > self.max_length:
                self.found = -1
                return 

        # pokud se změnila délka, tak změníme i předpřipravené data pro hešovací funkci
        if w[15] != length * 8:
            w[length / 4] = 0x80 << ((3 - (length % 4)) * 8)

            w[15] = length * 8
        
        
        for i in reversed(range(length - 1)):
            j = (j - (j % self.charset_length) - self.charset_length) / self.charset_length
            k = i / 4
            l = (3 - (i % 4)) * 8
            w[k] &= <unsigned int>0xffffffff ^ (0xff << l)
            w[k] |= self.charset[j % self.charset_length] << l
        
        holder.length = length
        holder.offset = j % self.charset_length

cdef char* _brute_force(Generator generator, hash_t target, int min_length, unsigned int num_threads) nogil: 
    cdef unsigned int i, j
    cdef unsigned int* w
    cdef holder_t* holder
    # pomocné proměnné, pro uchování výpočtů, které se provádějí vícekrát při generování hesel
    cdef unsigned int tmp1, tmp2, tmp3

    with parallel(num_threads = num_threads):
        # nastavení lokálních proměnných pro každé vlákno
        i = 0
        j = 0
        tmp1 = 0
        tmp2 = 0
        tmp3 = 0
        w = <unsigned int*>malloc(sizeof(unsigned int) * 80)
        for i in range(15):
            w[i] = 0
        holder = <holder_t*>malloc(sizeof(holder_t))

        w[0] = 0x80 << (min_length * 2)

        w[15] = min_length
        
        while not generator.found:
            generator.next(w, holder)

            tmp1 = <unsigned int>0xffffffff ^ (0xff << ((4 - holder.length % 4) * 8))
            tmp2 = (3 - ((holder.length - 1) % 4)) * 8
            tmp3 = (holder.length - 1) / 4

            for i in range(generator.buff_size):
                w[tmp3] &= tmp1
                w[tmp3] |= generator.charset[i + holder.offset] << tmp2

                if hashes_equals(_sha1(w), target):
                    generator.password = <char*>malloc(sizeof(char) * holder.length + 1)
                    for j in range(holder.length):
                        generator.password[j] = (w[j / 4] >> ((3 - (j % 4)) * 8)) & 0xff
                    generator.password[holder.length] = '\0'
                    generator.found = 1
                    break
        free(w)
        free(holder)
    
    return generator.password

cdef unsigned int rol(unsigned int n, unsigned int b) nogil:
    return ((n << b) | (n >> (32 - b)))

# definice konstant pro hešovací funkci
cdef unsigned int h0 = 0x67452301
cdef unsigned int h1 = 0xefcdab89
cdef unsigned int h2 = 0x98badcfe
cdef unsigned int h3 = 0x10325476
cdef unsigned int h4 = 0xc3d2e1f0
cdef unsigned int* k = [0x5a827999, 0x6ed9eba1, 0x8f1bbcdc, 0xca62c1d6]

# zjednodušená verze sha1 - předpokládáme, že heslo nebude delší než 55 znaků
# zadaný parametr je již předpřipravený (přidaná 1 na konec hesla, zarovnán na 512 bitů a na konci vložená délka hešovaného slova) 
cdef hash_t _sha1(unsigned int* w) nogil:
    cdef unsigned int i

    for i in range(16, 80):
        w[i] = rol(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1)

    cdef unsigned int a = h0
    cdef unsigned int b = h1
    cdef unsigned int c = h2
    cdef unsigned int d = h3
    cdef unsigned int e = h4
    cdef unsigned int f, temp

    for i in range(20):
        f = (b & c) | ((~b) & d)

        temp = rol(a, 5) + f + e + k[0] + w[i]
        e = d
        d = c
        c = rol(b, 30)
        b = a
        a = temp
    for i in range(20, 40):
        f = b ^ c ^ d

        temp = rol(a, 5) + f + e + k[1] + w[i]
        e = d
        d = c
        c = rol(b, 30)
        b = a
        a = temp
    for i in range(40, 60):
        f = (b & c) | (b & d) | (c & d)

        temp = rol(a, 5) + f + e + k[2] + w[i]
        e = d
        d = c
        c = rol(b, 30)
        b = a
        a = temp
    for i in range(60, 80):
        f = b ^ c ^ d

        temp = rol(a, 5) + f + e + k[3] + w[i]
        e = d
        d = c
        c = rol(b, 30)
        b = a
        a = temp

    cdef hash_t hash
    hash.h0 = h0 + a
    hash.h1 = h1 + b
    hash.h2 = h2 + c
    hash.h3 = h3 + d
    hash.h4 = h4 + e
    return hash

cdef unsigned char hashes_equals(hash_t first, hash_t second) nogil:
    return first.h0 == second.h0 and first.h1 == second.h1 and first.h2 == second.h2 and first.h3 == second.h3 and first.h4 == second.h4

# definice funkcí volatelných z pythonu

def sha1(const char* data):
    cdef unsigned int* w = <unsigned int*>malloc(sizeof(unsigned int) * 80)
    cdef unsigned int length = strlen(data)
    cdef unsigned int i

    for i in range(15):
        w[i] = 0

    for i in range(length):
        w[i / 4] |= data[i] << ((3 - (i % 4)) * 8)

    w[length / 4] |= 0x80 << ((3 - (length % 4)) * 8)

    w[15] = length * 8

    cdef hash_t hash = _sha1(w)
    return (hash.h0, hash.h1, hash.h2, hash.h3, hash.h4)

# buff_size musí být dělitelem délky možných znaků
def brute_force(const char[] charset, unsigned int h0, unsigned int h1, unsigned int h2, unsigned int h3, unsigned int h4, int min_length = 1, int max_length = 6, unsigned int num_threads = 1, unsigned int buff_size = 1):    
    cdef hash_t target
    target.h0 = h0
    target.h1 = h1
    target.h2 = h2
    target.h3 = h3
    target.h4 = h4
    
    cdef Generator generator = Generator(charset, min_length, max_length, buff_size)
    cdef char* password = _brute_force(generator, target, min_length, num_threads)

    if password:
        return password
    return -1

def from_hex(hash):
    return (int(hash[:8], 16), int(hash[8:16], 16), int(hash[16:24], 16), int(hash[24:32], 16), int(hash[32:], 16))

def to_hex(h0, h1, h2, h3, h4):
    return '%08x%08x%08x%08x%08x' % (h0, h1, h2, h3, h4)

