import os
import json
import urllib.request
import time

import numpy as np

from rich import inspect
from rich.pretty import pprint
from rich.progress import track
from rich.console import Console

console = Console()

from rich.traceback import install
install(show_locals=True)

class EnglandCOVID:
    def __init__(self, verbose: bool = False, lags: int = 8, split=0.75) -> None:
        self.name = "EnglandCOVID"
        self.lags = lags
        self.split = split

        self._graph_attr = {}
        self._graph_updates = {}
        self._max_num_nodes = 0

        self._local_file_path = "england_covid.json"
        self._url_path = "https://raw.githubusercontent.com/benedekrozemberczki/pytorch_geometric_temporal/master/dataset/england_covid.json"
        self._verbose = verbose

        self._load_dataset()
        self.total_timestamps = self._dataset["time_periods"]
        self._get_edge_info()
        self._get_targets_and_features()
        self._presort_edge_weights()

    def get_graph_data(self):
        return self._graph_updates, self._max_num_nodes

    def _load_dataset(self) -> None:
        if self._is_local_exists():
            # loading the dataset from the local folder
            if self._verbose:
                console.log(f"Loading [cyan]{self.name}[/cyan] dataset locally")
            with open(self._local_file_path) as dataset_json:
                self._dataset = json.load(dataset_json)
        else:
            # loading the dataset by downloading them online
            if self._verbose:
                console.log(f"Downloading [cyan]{self.name}[/cyan] dataset")
            self._dataset = json.loads(urllib.request.urlopen(self._url_path).read())

            # TODO: Fix local file loadup
            # saving the dataset dictionary as a JSON file in local
            # with open(self._local_file_path, "w") as fp:
            #     json.dump(self._dataset, fp)
            #     if self._verbose:
            #         console.log(
            #             f"Successfully dowloaded [cyan]WikiMath[/cyan] dataset to [green]{self._local_file_path}[/green]"
            #         )

    def _get_edge_info(self):
        # getting the edge_list and edge_weights
        self._edge_list = []
        self._edge_weights = []

        for time in range(self._dataset["time_periods"] - self.lags):
            time_edge_list = []
            time_edge_weights = []

            for edge in self._dataset["edge_mapping"]["edge_index"][str(time)]:
                time_edge_list.append((edge[0], edge[1]))

            for weight in self._dataset["edge_mapping"]["edge_weight"][str(time)]:
                time_edge_weights.append(weight)

            self._edge_list.append(time_edge_list)
            self._edge_weights.append(time_edge_weights)

    def _get_targets_and_features(self):
        stacked_target = np.array(self._dataset["y"])
        standardized_target = (stacked_target - np.mean(stacked_target, axis=0)) / (
            np.std(stacked_target, axis=0) + 10**-10
        )

        self._all_features = [
            standardized_target[i : i + self.lags, :].T
            for i in range(self._dataset["time_periods"] - self.lags)
        ]
        self._all_targets = [
            standardized_target[i + self.lags, :].T
            for i in range(self._dataset["time_periods"] - self.lags)
        ]

    def _presort_edge_weights(self):
        """
        Presorting edges according to (dest,src) since that is how eids are formed
        allowing forward and backward kernel to access edge weights
        """
        final_edges_lst = []
        final_edge_weights_lst = []

        for i in range(len(self._edge_list)):
            src_list = [edge[0] for edge in self._edge_list[i]]
            dst_list = [edge[1] for edge in self._edge_list[i]]
            weights = self._edge_weights[i]

            edge_info_list = []
            sorted_edges_lst = []
            sorted_edge_weights_lst = []

            for j in range(len(weights)):
                edge_info = (src_list[j], dst_list[j], weights[j])
                edge_info_list.append(edge_info)

            # since it has to be sorted according to the reverse order
            sorted_edge_info_list = sorted(
                edge_info_list, key=lambda element: (element[1], element[0])
            )

            time_edge = []

            for edge in sorted_edge_info_list:
                time_edge.append((edge[0], edge[1]))
                sorted_edge_weights_lst.append(edge[2])

            final_edges_lst.append(time_edge)
            final_edge_weights_lst.append(np.array(sorted_edge_weights_lst))

        self._edge_list = final_edges_lst
        self._edge_weights = final_edge_weights_lst

    def get_edges(self):
        return self._edge_list

    def get_edge_weights(self):
        return self._edge_weights

    def get_all_features(self):
        return self._all_features

    def get_all_targets(self):
        return self._all_targets

    def _is_local_exists(self) -> bool:
        # TODO: Fix local path issue
        return True
        return os.path.exists(self._local_file_path)
