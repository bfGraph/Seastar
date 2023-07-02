#! /bin/bash
# Naming scheme (pygt|seastar)_(dataset_name)_T(cutoff_time|whole)_B(backprop_every|whole)__H(num_hidden)_F(feature_size)

# (Static Temporal PYG-T)
cd static-temporal-tgcn/pygt

# ---- (PYGT) WikiMaths ----
echo "Starting PyG-T Wikimaths script for different feature sizes"
for i in {8..80..8}
do
        hidden_units=$((i*2))
        python3 train.py --dataset wiki --num-epochs 10 --feat-size $i --num-hidden $hidden_units > ../../results/static-temporal/pygt_wikimaths_Twhole_Bwhole_H$hidden_units\_F$i.txt
        echo "Finished executing PyG-T Wikimaths script for F=$i"
done

echo "Starting PyG-T Wikimaths script for different sequence lengths"
for i in {100..700..100}
do
        python3 train.py --dataset wiki --num-epochs 10 --feat-size 8 --num-hidden 16 --backprop-every $i  > ../../results/static-temporal/pygt_wikimaths_Twhole_B$i\_H16_F8.txt
        echo "Finished executing PyG-T Wikimaths script for seq_len=$i"
done

# ---- (PYGT) Windmill----

echo "Starting PyG-T Windmill script for different feature sizes"
for i in {8..80..8}
do
        hidden_units=$((i*2))
        python3 train.py --dataset windmill --num-epochs 10 --feat-size $i --num-hidden $hidden_units --backprop-every 1000  --cutoff-time 3000 > ../../results/static-temporal/pygt_windmill_T3000_B1000_H$hidden_units\_F$i.txt
        echo "Finished executing PyG-T Windmill script for F=$i"
done

echo "Starting PyG-T Windmill script for different sequence lengths"
for i in {250..3000..250}
do
        python3 train.py --dataset windmill --num-epochs 10 --feat-size 8 --num-hidden 16 --backprop-every $i --cutoff-time 3000 > ../../results/static-temporal/pygt_windmill_T3000_B$i\_H16_F8.txt
        echo "Finished executing PyG-T Windmill script for seq_len=$i"
done

cd ../..

# (Static Temporal Seastar)
cd static-temporal-tgcn/seastar

#  ---- (SEASTAR) WikiMaths ----

echo "Starting Seastar Wikimaths script for different feature sizes"
for i in {8..80..8}
do
        hidden_units=$((i*2))
        python3 train.py --dataset wiki --num-epochs 10 --feat-size $i --num-hidden $hidden_units > ../../results/static-temporal/seastar_wikimaths_Twhole_Bwhole_H$hidden_units\_F$i.txt
        echo "Finished executing Seastar Wikimaths script for F=$i"
done

echo "Starting Seastar Wikimaths script for different feature sequence lengths"
for i in {100..700..100}
do
        python3 train.py --dataset wiki --num-epochs 10 --feat-size 8 --num-hidden 16 --backprop-every $i  > ../../results/static-temporal/seastar_wikimaths_Twhole_B$i\_H16_F8.txt
        echo "Finished executing Seastar Wikimaths script for seq_len=$i"
done

#  ---- (SEASTAR) Windmill ----

echo "Starting Seastar Windmill script for different feature sizes"
for i in {8..80..8}
do
        hidden_units=$((i*2))
        python3 train.py --dataset windmill --num-epochs 10 --feat-size $i --num-hidden $hidden_units --backprop-every 1000 --cutoff-time 3000 > ../../results/static-temporal/seastar_windmill_T3000_B1000_H$hidden_units\_F$i.txt
        echo "Finished executing Seastar Windmill script for F=$i"
done

echo "Starting Seastar Windmill script for different sequence lengths"
for i in {250..3000..250}
do
        python3 train.py --dataset windmill --num-epochs 10 --feat-size 8 --num-hidden 16 --backprop-every $i --cutoff-time 3000 > ../../results/static-temporal/seastar_wikimaths_T3000_B$i\_H16_F8.txt
        echo "Finished executing Seastar Windmill script for seq_len=$i"
done

cd ../..
