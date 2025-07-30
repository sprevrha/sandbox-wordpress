# make_env.mk
# load_env_vars function accepts one or more arguments: paths to .env files.
# All arguments passed to $(call load_env_vars, ...) will be treated as file paths.
#
# Usage: $(call load_env_vars,path/to/file1.env path/to/file2.env ...)
# Variables are loaded from left to right in the list of files.
# Later files in the list will override values from earlier files,
# unless the variable is already defined in the shell environment.

# Define 'empty' and 'space' variables for robust string manipulation
empty :=
space := $(empty) $(empty)
comma := ,

# Function to debug and print messages if DEBUG is set to ON
# This function can be used to print debug messages conditionally.
$(if $(DEBUG_MAKE),,$(eval DEBUG_MAKE := OFF))
define debug
$(if $(filter ON,$(DEBUG_MAKE)),$(info $(1)))
endef

# define decode_b64
# $(shell \
#   printf '%s\n' '$(subst b64:,,$(1))' | \
#   sed -e 's/\([$][{(]\)/\\\1/g' | \
#   base64 -d)
# endef

# Function to load environment variables from a file
# This function reads the specified file(s) and sets the variables in the Makefile.
# It handles comments, whitespace, and variable expansion.
# It also supports variable expansion for values ending with a dollar sign ($).
# It will not override variables that are already set in the shell environment.
define load_env_vars
$(eval __env_files := $(strip $(subst $(comma),$(space),$(1))))
$(call debug, Loading environment variables from: $(__env_files))
$(eval __env_pairs := $(shell awk '\
/^[[:space:]]*[^#][^=+]*[+]?=/\
{\
    op="=";\
    if (match($$0, /^[^#=+]*\+=/)) op="+=";\
    if (match($$0, /^[^#=:]*:=/)) op="=";\
	key=$$0; sub(/[:\+]?=.*/,"",key); sub(/^[ \t]+|[ \t]+$$/,"",key);\
	val=substr($$0,index($$0,"=")+1);\
    # Remove in-line trailing comments and whitespace
		sub(/[ \t]*#.*$$/, "", val);\
    # Preserve escaped dollar signs by replacing them with ???, to be reconstructed later.
    gsub(/\\\\\\$$/, "???", val);\
    # Preserve $ signs in values by replacing them with $$$$ to be expanded later. 
    gsub(/\$$/,"$$$$",val);\
    # Remove leading and trailing whitespace
    sub(/^[ \t]+|[ \t]+$$/,"",val);\
    # Preserve commas and space inside bracketed expressions.
    _start_bracket_pos_ = index(val, "[");\
    _end_bracket_pos_ = index(val, "]");\
    if (_start_bracket_pos_ > 0 && _end_bracket_pos_ > _start_bracket_pos_) {\
      _inner_content_length_ = _end_bracket_pos_ - _start_bracket_pos_ - 1;\
      _inner_content_ = substr(val, _start_bracket_pos_ + 1, _inner_content_length_);\
      gsub(/,/, "~~~", _inner_content_);\
      gsub(/ /, "!!!", _inner_content_);\
      val = substr(val, 1, _start_bracket_pos_) _inner_content_ substr(val, _end_bracket_pos_);\
    }\
    gsub(/[ \t]+/, ",", val);\
    printf "%s>>>%s>>>%s|||", key, op, val\
}' $(__env_files)))
$(call debug, Loading environment variables from string: $(__env_pairs))
$(foreach __pair,$(subst |||,$(space),$(__env_pairs)),\
  $(call debug,Processing string: $(__pair))\
  $(if $(__pair),\
    $(eval key := $(strip $(word 1,$(subst >>>,$(space),$(__pair)))))\
    $(call debug,Key: $(key))\
    $(eval op := $(strip $(word 2,$(subst >>>,$(space),$(__pair)))))\
    $(call debug,Operator: $(op))\
    $(eval value := $(strip $(word 3,$(subst >>>,$(space),$(__pair)))))\
    $(call debug,Value: $(value))\
    $(if $(and $(key),$(filter-out \#%,$(key))),\
        $(call debug,Processing value: $(value))\
        $(if $(filter environment, $(origin $(key))),,\
          $(call debug,Variable expansion for $(key))\
          $(if $(filter +=,$(op)),\
            $(call debug,Found += operator for $(key): appending)\
            $(eval cval := $($(key)) $(subst $(comma),$(space),$(value)))\
          ,\
            $(call debug,Found = operator for $(key): replacing)\
            $(eval cval := $(subst $(comma),$(space),$(value)))\
          )\
        )\
      $(eval cval := $(subst ~~~,$(comma),$(cval)))\
      $(eval cval := $(subst !!!,$(space),$(cval)))\
      $(eval cval := $(subst ???,$$$$$$$$,$(cval)))\
      $(call debug, Setting variable: $(key) = $(cval))\
      $(eval $(key) := $(cval))\
      $(eval export $(key) := $(cval))\
    )\
  )\
)
endef

