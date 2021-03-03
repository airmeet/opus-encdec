INPUT_DIR=./src
OUTPUT_DIR=./dist
OUTPUT_DIR_UNMINIFIED=./dist
OUTPUT_WASM_DIR=./dist
OUTPUT_WASM_DIR_UNMINIFIED=./dist
EMCC_OPTS=-O3 -s NO_DYNAMIC_EXECUTION=1 -s NO_FILESYSTEM=1
DEFAULT_EXPORTS:='_malloc','_free'

LIBOPUS_ENCODER_SRC=$(INPUT_DIR)/oggOpusEncoder.js
LIBOPUS_DECODER_SRC=$(INPUT_DIR)/oggOpusDecoder.js

UMD_PREFIX=$(INPUT_DIR)/umd-wrapper/prefix.js
UMD_DECODER_SUFFIX=$(INPUT_DIR)/umd-wrapper/suffix_dec.js
UMD_ENCODER_SUFFIX=$(INPUT_DIR)/umd-wrapper/suffix_enc.js
UMD_RESAMPLER_SUFFIX=$(INPUT_DIR)/umd-wrapper/suffix_resampler.js

LIBOPUS_ENCODER_MIN=$(OUTPUT_DIR)/libopus-encoder.min.js
LIBOPUS_ENCODER=$(OUTPUT_DIR_UNMINIFIED)/libopus-encoder.js
LIBOPUS_DECODER_MIN=$(OUTPUT_DIR)/libopus-decoder.min.js
LIBOPUS_DECODER=$(OUTPUT_DIR_UNMINIFIED)/libopus-decoder.js
LIBSPEEXDSP_RESAMPLER_MIN=$(OUTPUT_DIR)/resampler.min.js
LIBSPEEXDSP_RESAMPLER=$(OUTPUT_DIR_UNMINIFIED)/resampler.js

LIBOPUS_ENCODER_WASM_MIN=$(OUTPUT_WASM_DIR)/libopus-encoder.wasm.min.js
LIBOPUS_ENCODER_WASM=$(OUTPUT_WASM_DIR_UNMINIFIED)/libopus-encoder.wasm.js
LIBOPUS_DECODER_WASM_MIN=$(OUTPUT_WASM_DIR)/libopus-decoder.wasm.min.js
LIBOPUS_DECODER_WASM=$(OUTPUT_WASM_DIR_UNMINIFIED)/libopus-decoder.wasm.js
LIBSPEEXDSP_RESAMPLER_WASM_MIN=$(OUTPUT_WASM_DIR)/resampler.wasm.min.js
LIBSPEEXDSP_RESAMPLER_WASM=$(OUTPUT_WASM_DIR_UNMINIFIED)/resampler.wasm.js

LIBOPUS_DIR=./opus
LIBOPUS_OBJ=$(LIBOPUS_DIR)/.libs/libopus.a
LIBOPUS_ENCODER_EXPORTS:='_opus_encoder_create','_opus_encode_float','_opus_encoder_ctl','_opus_encoder_destroy'
LIBOPUS_DECODER_EXPORTS:='_opus_decoder_create','_opus_decode_float','_opus_decoder_destroy'

LIBSPEEXDSP_DIR=./speexdsp
LIBSPEEXDSP_OBJ=$(LIBSPEEXDSP_DIR)/libspeexdsp/.libs/libspeexdsp.a
LIBSPEEXDSP_EXPORTS:='_speex_resampler_init','_speex_resampler_process_interleaved_float','_speex_resampler_destroy'

RECORDER_MIN=$(OUTPUT_DIR)/recorder.min.js
RECORDER=$(OUTPUT_DIR_UNMINIFIED)/recorder.js
RECORDER_SRC=$(INPUT_DIR)/recorder.js

WAVE_WORKER_MIN=$(OUTPUT_DIR)/waveWorker.min.js
WAVE_WORKER=$(OUTPUT_DIR_UNMINIFIED)/waveWorker.js
WAVE_WORKER_SRC=$(INPUT_DIR)/waveWorker.js


default: $(LIBOPUS_ENCODER) $(LIBOPUS_ENCODER_MIN) $(LIBOPUS_DECODER) $(LIBOPUS_DECODER_MIN) \
	$(LIBOPUS_ENCODER_WASM) $(LIBOPUS_ENCODER_WASM_MIN) $(LIBOPUS_DECODER_WASM) $(LIBOPUS_DECODER_WASM_MIN) \
	$(LIBSPEEXDSP_RESAMPLER) $(LIBSPEEXDSP_RESAMPLER_MIN) $(LIBSPEEXDSP_RESAMPLER_WASM) $(LIBSPEEXDSP_RESAMPLER_WASM_MIN) #\
	# $(RECORDER) $(RECORDER_MIN) $(WAVE_WORKER) $(WAVE_WORKER_MIN) \
	# test

cleanDist:
	rm -rf $(OUTPUT_DIR) $(OUTPUT_DIR_UNMINIFIED)
	mkdir $(OUTPUT_DIR)
	mkdir $(OUTPUT_DIR_UNMINIFIED)

cleanAll: cleanDist
	rm -rf $(LIBOPUS_DIR) $(LIBSPEEXDSP_DIR)

test:
	# Tests need to run relative to `dist` folder for wasm file import
	cd $(OUTPUT_DIR); node --expose-wasm ../test.js

.PHONY: test

$(LIBOPUS_DIR)/autogen.sh $(LIBSPEEXDSP_DIR)/autogen.sh:
	git submodule update --init

$(LIBOPUS_OBJ): $(LIBOPUS_DIR)/autogen.sh
	cd $(LIBOPUS_DIR); ./autogen.sh
	cd $(LIBOPUS_DIR); emconfigure ./configure --disable-extra-programs --disable-doc --disable-intrinsics --disable-rtcd --disable-stack-protector
	cd $(LIBOPUS_DIR); emmake make

$(LIBSPEEXDSP_OBJ): $(LIBSPEEXDSP_DIR)/autogen.sh
	cd $(LIBSPEEXDSP_DIR); ./autogen.sh
	cd $(LIBSPEEXDSP_DIR); emconfigure ./configure --disable-examples
	cd $(LIBSPEEXDSP_DIR); emmake make

# ################# WASM ######################

$(LIBOPUS_ENCODER_WASM): $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s WASM=1 -s BINARYEN_ASYNC_COMPILATION=0 -g3 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_ENCODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_ENCODER_SUFFIX) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

$(LIBOPUS_ENCODER_WASM_MIN): $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s WASM=1 -s BINARYEN_ASYNC_COMPILATION=0 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_ENCODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_ENCODER_SUFFIX) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

$(LIBOPUS_DECODER_WASM): $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -g3 -s WASM=1 -s BINARYEN_ASYNC_COMPILATION=0 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_DECODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_DECODER_SUFFIX) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

$(LIBOPUS_DECODER_WASM_MIN): $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s WASM=1 -s BINARYEN_ASYNC_COMPILATION=0 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_DECODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_DECODER_SUFFIX) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

$(LIBSPEEXDSP_RESAMPLER_WASM): $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -g3 -s WASM=1 -s BINARYEN_ASYNC_COMPILATION=0 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_RESAMPLER_SUFFIX) $(LIBSPEEXDSP_OBJ)

$(LIBSPEEXDSP_RESAMPLER_WASM_MIN): $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s WASM=1 -s BINARYEN_ASYNC_COMPILATION=0 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_RESAMPLER_SUFFIX) $(LIBSPEEXDSP_OBJ)

# ################# pure JS ######################

$(LIBOPUS_ENCODER): $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s WASM=0 -s BINARYEN_ASYNC_COMPILATION=0 -s SINGLE_FILE=1 -g3 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_ENCODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_ENCODER_SUFFIX) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

$(LIBOPUS_ENCODER_MIN): $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
	emcc -o $@ $(EMCC_OPTS) -s WASM=0 -s BINARYEN_ASYNC_COMPILATION=0 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_ENCODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_ENCODER_SUFFIX) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

$(LIBOPUS_DECODER): $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
#	npm run webpack -- --config webpack.config.js -d --output-library DecoderWorker $(LIBOPUS_DECODER_SRC) -o $@
	emcc -o $@ $(EMCC_OPTS) -g3 -s WASM=0 -s BINARYEN_ASYNC_COMPILATION=0 -s SINGLE_FILE=1 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_DECODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_DECODER_SUFFIX) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

$(LIBOPUS_DECODER_MIN): $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)
#	npm run webpack -- --config webpack.config.js -p --output-library DecoderWorker $(LIBOPUS_DECODER_SRC) -o $@
	emcc -o $@ $(EMCC_OPTS) -s WASM=0 -s BINARYEN_ASYNC_COMPILATION=0 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBOPUS_DECODER_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_DECODER_SUFFIX) $(LIBOPUS_OBJ) $(LIBSPEEXDSP_OBJ)

$(LIBSPEEXDSP_RESAMPLER): $(LIBSPEEXDSP_OBJ)
#	npm run webpack -- --config webpack.config.js -d --output-library DecoderWorker $(LIBOPUS_DECODER_SRC) -o $@
	emcc -o $@ $(EMCC_OPTS) -g3 -s WASM=0 -s BINARYEN_ASYNC_COMPILATION=0 -s SINGLE_FILE=1 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_RESAMPLER_SUFFIX) $(LIBSPEEXDSP_OBJ)

$(LIBSPEEXDSP_RESAMPLER_MIN): $(LIBSPEEXDSP_OBJ)
#	npm run webpack -- --config webpack.config.js -p --output-library DecoderWorker $(LIBOPUS_DECODER_SRC) -o $@
	emcc -o $@ $(EMCC_OPTS) -s WASM=0 -s BINARYEN_ASYNC_COMPILATION=0 -s EXPORTED_FUNCTIONS="[$(DEFAULT_EXPORTS),$(LIBSPEEXDSP_EXPORTS)]" --pre-js $(UMD_PREFIX) --post-js $(UMD_RESAMPLER_SUFFIX) $(LIBSPEEXDSP_OBJ)

$(RECORDER): $(RECORDER_SRC)
	npm run webpack -- --config webpack.config.js -d --output-library Recorder $(RECORDER_SRC) -o $@

$(RECORDER_MIN): $(RECORDER_SRC)
	npm run webpack -- --config webpack.config.js -p --output-library Recorder $(RECORDER_SRC) -o $@

$(WAVE_WORKER): $(WAVE_WORKER_SRC)
	npm run webpack -- -d $(WAVE_WORKER_SRC) -o $@

$(WAVE_WORKER_MIN): $(WAVE_WORKER_SRC)
	npm run webpack -- -p $(WAVE_WORKER_SRC) -o $@
