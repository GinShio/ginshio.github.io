### FUNCTIONS
define rwildcard
	$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))
endef

### VARIABLES
BEANSRCDIR := $(ORGMODE_DIRECTORY)/ledger

decryptobjects := $(call rwildcard,$(BEANSRCDIR),*.beancount)
encryptobjects :=
ifeq ($(strip $(decryptobjects)),)
	encryptobjects := $(call rwildcard,$(BEANSRCDIR),*.beancrypt)
	decryptobjects := $(patsubst %.beancrypt,%.beancount,$(encryptobjects))
else
	encryptobjects := $(patsubst %.beancount,%.beancrypt,$(decryptobjects))
endif
ifndef PASSPHRASE
	ifneq ($(EXECTARGET),CLEANALL)
		$(error "PASSPHRASE NOT DEFINED")
	endif
endif

### TARGETS
.PHONY: encrypt decrypt cleanall
encrypt: $(encryptobjects)

decrypt: $(decryptobjects)

cleanall:
	@rm -rf $(call rwildcard,$(BEANSRCDIR),*.beancrypt)

$(encryptobjects): %.beancrypt: %.beancount
	@openssl enc -aes-256-cbc -e -a -k "$(PASSPHRASE)" -salt -pbkdf2 -iter 100000 -in $< -out $@

$(decryptobjects): %.beancount: %.beancrypt
	@openssl enc -aes-256-cbc -d -a -k "$(PASSPHRASE)" -pbkdf2 -iter 100000 -in $< -out $@
