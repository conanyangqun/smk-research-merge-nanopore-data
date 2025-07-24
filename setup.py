from setuptools import setup, find_packages

setup(
    name='pyq_merge_nanopore_data',
    version='0.1.0',
    author='Yang Qun',
    packages=find_packages(),
    install_requires=[
        'pandas>=1.0.0',
        'snakemake>=8.0.0',
        'nanostat',
    ],
    description='A package for merging Nanopore sequencing data',
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    url='https://github.com/conanyangqun',
)
