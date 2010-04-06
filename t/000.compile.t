use Test::More;
eval "use Test::Compile 0.09";
Test::More->builder->BAIL_OUT("Test::Compile 0.09 required for testing compilation: $@") if $@;
all_pm_files_ok();