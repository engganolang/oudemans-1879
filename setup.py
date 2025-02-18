from setuptools import setup


setup(
    name='cldfbench_oudemans1879',
    py_modules=['cldfbench_oudemans1879'],
    include_package_data=True,
    zip_safe=False,
    entry_points={
        'cldfbench.dataset': [
            'oudemans1879=cldfbench_oudemans1879:Dataset',
        ]
    },
    install_requires=[
        'cldfbench',
    ],
    extras_require={
        'test': [
            'pytest-cldf',
        ],
    },
)
