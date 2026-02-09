## 📖 Manual Development

<details>
<summary>Expand for more...</summary>

## QEMU

#### Clone repo
```
git clone --depth=1 --branch "v10.2.0" "https://gitlab.com/qemu-project/qemu.git"
```

#### Git diff patched repo
```
git diff HEAD > "qemu-10.2.0.patch"
```

#### Patch repo
```
git apply < "qemu-10.2.0.patch"
```

## EDK2

#### Clone repo
```
git clone --depth=1 --branch "edk2-stable202511" "https://github.com/tianocore/edk2.git"
```

#### Git diff patched repo
```
git diff HEAD > "edk2-stable202511.patch"
```

#### Patch repo
```
git apply < "edk2-stable202511.patch"
```
