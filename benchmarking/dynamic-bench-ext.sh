#! /bin/bash
# Naming scheme (pygt|seastar_(seastar_type))_(dataset_name)_T(cutoff_time|whole)_S(slide_size)_B(backprop_every|whole)_H(hidden_units)_F(feature_size)

# Dynamic Temporal PyG-T
cd dynamic-temporal-tgcn/pygt

echo "Running PyG-T on all script for different slide sizes"
for dataset in math wikitalk askubuntu superuser stackoverflow reddit_title reddit_body email bitcoin_otc
do
    for slide_size in 2.0 4.0 6.0 8.0 10.0
    do
        python3 train.py --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden 64 --feat-size 32 --backprop-every 5 > ../../results/dynamic-temporal/pygt_$dataset\_Twhole_S$i\_B5_H64_F32.txt
        echo "Finished executing PyG-T $dataset script for S=$slide_size"
    done
done

echo "Running PyG-T (wikitalk, askubuntu, superuser, stackoverflow) script for different feature sizes"
for dataset in wikitalk askubuntu superuser stackoverflow
do
    for slide_size in 5.0
    do
        for feat_size in {8..80..8}
        do
            hidden_units=$((feat_size*2))
            python3 train.py --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden $hidden_units --feat-size $feat_size --backprop-every 5 > ../../results/dynamic-temporal/pygt_$dataset\_Twhole_S$i\_B5_H$hidden_units\_F$feat_size.txt
            echo "Finished executing PyG-T $dataset for F=$feat_size"
        done
    done
done

echo "Running PyG-T (math, reddit_body, reddit_title) script for different feature sizes"
for dataset in math reddit_body reddit_title
do
    for slide_size in 5.0
    do
        for feat_size in {50..500..50}
        do
            hidden_units=$((feat_size*2))
            python3 train.py --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden $hidden_units --feat-size $feat_size --backprop-every 5 > ../../results/dynamic-temporal/pygt_$dataset\_Twhole_S$i\_B5_H$hidden_units\_F$feat_size.txt
            echo "Finished executing PyG-T $dataset for F=$feat_size"
        done
    done
done

echo "Running PyG-T (bitcoin_otc, email) script for different feature sizes"
for dataset in bitcoin_otc email
do
    for slide_size in 5.0
    do
        for feat_size in {200..2000..200}
        do
            hidden_units=$((feat_size*2))
            python3 train.py --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden $hidden_units --feat-size $feat_size --backprop-every 5 > ../../results/dynamic-temporal/pygt_$dataset\_Twhole_S$i\_B5_H$hidden_units\_F$feat_size.txt
            echo "Finished executing PyG-T $dataset for F=$feat_size"
        done
    done
done

cd ../..

# Dynamic Temporal Seastar
cd dynamic-temporal-tgcn/seastar

echo "Running Seastar on all script for different slide sizes"

for dataset in math wikitalk askubuntu superuser stackoverflow reddit_title reddit_body email bitcoin_otc
do
    for type in naive pcsr gpma
    do
        for slide_size in 2.0 4.0 6.0 8.0 10.0
        do
            python3 train.py --type $type --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden 64 --feat-size 32 --backprop-every 5 > ../../results/dynamic-temporal/seastar_$type\_$dataset\_Twhole_S$i\_B5_H64_F32.txt
            echo "Finished executing Seastar $dataset for type $type script for S=$slide_size"
        done
    done
done

echo "Running Seastar (wikitalk, askubuntu, superuser, stackoverflow) script for different feature sizes"
for dataset in wikitalk askubuntu superuser stackoverflow
do
    for type in naive pcsr gpma
    do
        for slide_size in 5.0
        do
            for feat_size in {8..80..8}
            do
                hidden_units=$((feat_size*2))
                python3 train.py --type $type --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden $hidden_units --feat-size $feat_size --backprop-every 5 > ../../results/dynamic-temporal/seastar_$type\_$dataset\_Twhole_S$i\_B5_H$hidden_units\_F$feat_size.txt
                echo "Finished executing Seastar $dataset for type $type for F=$feat_size"
            done
        done
    done
done

echo "Running Seastar (math, reddit_body, reddit_title) script for different feature sizes"
for dataset in math reddit_body reddit_title
do
    for type in naive pcsr gpma
    do
        for slide_size in 5.0
        do
            for feat_size in {50..500..50}
            do
                hidden_units=$((feat_size*2))
                python3 train.py --type $type --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden $hidden_units --feat-size $feat_size --backprop-every 5 > ../../results/dynamic-temporal/seastar_$type\_$dataset\_Twhole_S$i\_B5_H$hidden_units\_F$feat_size.txt
                echo "Finished executing PyG-T $dataset for F=$feat_size"
            done
        done
    done
done

echo "Running Seastar (bitcoin_otc, email) script for different feature sizes"
for dataset in bitcoin_otc email
do
    for type in naive pcsr gpma
    do
        for slide_size in 5.0
        do
            for feat_size in {200..2000..200}
            do
                hidden_units=$((feat_size*2))
                python3 train.py --type $type --dataset $dataset --num-epochs 10 --slide-size $slide_size --num-hidden $hidden_units --feat-size $feat_size --backprop-every 5 > ../../results/dynamic-temporal/seastar_$type\_$dataset\_Twhole_S$i\_B5_H$hidden_units\_F$feat_size.txt
                echo "Finished executing PyG-T $dataset for F=$feat_size"
            done
        done
    done
done

cd ../..