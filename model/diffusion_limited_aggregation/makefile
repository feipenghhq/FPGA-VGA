
run: clean dla_draw

dla_draw: dla_model
	./dla_model
	./dla_draw.py

dla_model:
	gcc -w -o dla_model dla_model.c

clean:
	rm -rf dla_model dla_model.csv