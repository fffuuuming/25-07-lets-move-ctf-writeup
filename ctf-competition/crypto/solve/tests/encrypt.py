#!/usr/bin/python2

#from secret import flag
flag = "flag{5Ui_M0Ve_CONtrAC7}"
import os
import random

mod = 2**64

def matmul(a,b):
    assert(len(a[0]) == len(b))
    c = []
    for i in range(len(a)):
        tmp = 0
        for j in range(len(b)):
            tmp = (tmp+a[i][j]*b[j])%mod
        c.append(tmp)
    return c

def matadd(a,b):
    assert len(a) == len(b)
    c = []
    for i in range(len(a)):
        c.append((a[i]+b[i])%mod)
    return c

n = len(flag)
f = list(map(ord, flag))
print(f)
a = []
random.seed(0)
for i in range(64):
    v = []
    for j in range(n):
        v.append(random.randrange(0,2**64))
    a.append(v)
    print(f'vector{v},')
# random.seed(os.urandom(32))
# k = []
# for i in range(64):
#     k.append(random.randrange(0,2**32))
# ans = matadd(matmul(a,f),k)

print(ans)
