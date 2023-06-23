#! /bin/bash
# Naming scheme (pygt|seastar_(seastar_type))_(dataset_name)_T(cutoff_time|whole)_S(slide_size)_B(backprop_every|whole)_H(hidden_units)_F(feature_size)

# Dynamic Temporal PyG-T
cd dynamic-temporal-tgcn/pygt

echo "Running PyG-T sx-mathoverflow script for different feature sizes"
for dataset in math
do
    for slide_size in 1.0
    do
        for feat_size in {8..80..8}
        do
            hidden_units=$((feat_size*2))
            python3 train.py --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden $hidden_units --feat-size $feat_size > ../../results/dynamic-temporal/pygt_$dataset\_Twhole_S$i\_Bwhole_H$hidden_units\_F$feat_size.txt
            echo "Finished executing PyG-T sx-mathoverflow script for F=$feat_size"
        done
    done
done

echo "Running PyG-T wiki-talk-temporal script for different feature sizes"
for dataset in wikitalk
do
    for slide_size in 1.0
    do
        for feat_size in {8..80..8}
        do
            hidden_units=$((feat_size*2))
            python3 train.py --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden $hidden_units --feat-size $feat_size --backprop-every 30 > ../../results/dynamic-temporal/pygt_$dataset\_Twhole_S$i\_B30_H$hidden_units\_F$feat_size.txt
            echo "Finished executing PyG-T wiki-talk-temporal script for F=$feat_size"
        done
    done
done

cd ../..

# Dynamic Temporal Seastar
cd dynamic-temporal-tgcn/seastar

echo "Running Seastar sx-mathoverflow script for different feature sizes"
for dataset in math 
do
    for type in naive gpma pcsr
    do
        for slide_size in 1.0
        do
            for feat_size in {8..80..8}
            do
                hidden_units=$((feat_size*2))
                python3 train.py --type $type --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden $hidden_units --feat-size $feat_size > ../../results/dynamic-temporal/seastar_$type\_$dataset\_Twhole_S$i\_Bwhole_H$hidden_units\_F$feat_size.txt
                echo "Finished executing Seastar sx-mathoverflow script for F=$feat_size"
            done
        done
    done
done

echo "Running Seastar wiki-talk-temporal script for different feature sizes"
for dataset in wikitalk
do
    for type in naive gpma pcsr
    do
        for slide_size in 1.0
        do
            for feat_size in {8..80..8}
            do
                hidden_units=$((feat_size*2))
                python3 train.py --type $type --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden $hidden_units --feat-size $feat_size --backprop-every 30 > ../../results/dynamic-temporal/seastar_$type\_$dataset\_Twhole_S$i\_B30_H$hidden_units\_F$feat_size.txt
                echo "Finished executing Seastar wiki-talk-temporal script for F=$feat_size"
            done
        done
    done
done

cd ../..