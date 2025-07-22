#from distutils.core import setup
from setuptools import setup # rams added setuptools is the current standard
import distutils.command.install
import os

#rams deleted the entire class, it is empty and non-functional
# class create_link(distutils.core.Command):
    
#     def run( self ):
#         #create a sym link to uniqprimer.py inside of /usr/local/bin
#        os.symlink(  ) 
        

setup( name='uniqprimer',
       description='A Python tool for finding primers unique to a given genome',
       author='John Herndon',
       author_email='johnlherndon@gmail.com',
       version='0.5.0',
       packages=[ 'primertools' ],
       scripts=[ 'uniqprimer.py' ],
       python_requires = '>=3.6', #rams added for installation
       data_files=[ ( '/usr/local/bin', [ 'uniqprimer.py' ] ) ] 
       )

