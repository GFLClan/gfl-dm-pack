CC := ../spcomp64
INCLUDE := -i ../include -i include
SRCS := gfldm gfldm-anim gfldm-autoreload gfldm-autosilencer gfldm-chat gfldm-livetop gfldm-noscopes gfldm-sounds gfldm-stats gfldm-teambalance gfldm-hsexplode gfldm-hitboxes gfldm-quakesounds gfldm-tags
COMPILED := $(addprefix compiled/, $(addsuffix .smx, $(SRCS)))
DEPS := include/gfldm.inc include/gfldm-chat.inc include/gfldm-noscopes.inc include/gfldm-stats.inc include/gfldm-clientprefs.inc include/gfldm-anim.inc

$(COMPILED): compiled/%.smx : %.sp $(DEPS)
	$(CC) $< $(INCLUDE) -o $@

.PHONY: all clean

all: $(COMPILED)

clean: 
	rm -f $(COMPILED)
