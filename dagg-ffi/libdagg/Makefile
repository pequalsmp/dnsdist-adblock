.PHONY : clean

SOURCES = $(shell echo *.c)
HEADERS = $(shell echo *.h)
OBJECTS = $(SOURCES:.c=.o)

INCSRC  =  -Ifilters/include
INCSRC  += -Ixxhash

CFLAGS 	= -fPIC -O2 -shared -fkeep-inline-functions -Wall -Werror $(INCSRC)
LDFLAGS = $(LDPATH) $(LDLIBS)

TARGET=libdagg.so

all: $(TARGET)

clean:
	rm -f $(OBJECTS) $(TARGET)

$(TARGET) : $(OBJECTS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJECTS) -o $@
