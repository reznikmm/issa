# issa

A commenting server similar to Disqus.
This is clone of [Isso](https://isso-comments.de/) in Ada.

## UNDER CONSTRUCTION!

## How to install AWS and Matreshka

```shell
sed -e '/ENABLE_SHARED=/s/false/true/' $HOME/.config/alire/indexes/community/repo/index/aw/aws/aws-24.0.0.toml
alr get matreshka_spikedog_awsd
cd matreshka_spikedog_awsd*
export LIBRARY_TYPE=relocatable
alr action -r post-fetch
sed -i '1iwith "gnatcoll";' ./alire/cache/dependencies/aws_24.0.0_2b75fe6d/install_dir/share/gpr/aws.gpr
#alr build
alr install

for J in matreshka_servlet \
 matreshka_spikedog_aws \
 matreshka_spikedog_api \
 matreshka_spikedog_core
do
alr exec -- gprinstall --mode=usage --no-project \
  --link-lib-subdir=bin --lib-subdir=bin \
  --prefix=$HOME/.alire -p -P $J
done

cp -v ./alire/cache/dependencies/aws_24.0.0_2b75fe6d/install_dir/lib/aws.relocatable/libaws.so ~/.alire/bin/

LD_LIBRARY_PATH=$HOME/.alire/bin ~/.alire/bin/spikedog_awsd
```
