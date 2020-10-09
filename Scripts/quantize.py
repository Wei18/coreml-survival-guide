# The mode argument should be one of:
#   linear
#   kmeans
#   dequantization
# 
# The number of bits should be between 1 and 8.

import sys
import coremltools as ct
from coremltools.models.neural_network import quantization_utils

if len(sys.argv) < 4:
    print("USAGE: %s <input_mlmodel> <output_mlmodel> <mode> <bits>" % sys.argv[0])
    sys.exit(1)  

input_model_path = sys.argv[1]
output_model_path = sys.argv[2]
mode = sys.argv[3]
nbits = int(sys.argv[4]) if len(sys.argv) > 4 else 8

model = ct.models.MLModel(input_model_path)  
quant_model = quantization_utils.quantize_weights(model, nbits, mode)
quant_model.save(output_model_path)
