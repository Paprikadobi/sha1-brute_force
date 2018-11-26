from distutils.core import setup, Extension
from Cython.Build import cythonize

import os

os.environ["CC"] = "/usr/local/Cellar/gcc/8.2.0/bin/gcc-8" 
os.environ["CXX"] = "/usr/local/Cellar/gcc/8.2.0/bin/gcc-8"
os.environ["FLIBS"] = "-L/usr/local/Cellar/gcc/8.2.0/lib/gcc/8"

# extensions = [Extension(
#                 "sha1.so",
#                 sources=["sha1.pyx"],
#                 extra_compile_args=["-openmp"],
#                 extra_link_args=["-openmp"]
#             )]

# setup(
#     ext_modules = cythonize(extensions)
# )

setup(ext_modules = cythonize(["sha1.pyx"]))

