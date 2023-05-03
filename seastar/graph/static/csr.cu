#include "stdio.h"
#include <vector>
#include <tuple>

#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include <thrust/remove.h>
#include <thrust/sort.h>
#include <cub/cub.cuh>

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

namespace py = pybind11;
using namespace pybind11::literals;

typedef thrust::device_vector<int> DEV_VEC;
#define RAW_PTR(x) thrust::raw_pointer_cast((x).data())

class CSR
{
public:
    thrust::host_vector<int> row_offset;
    thrust::host_vector<int> column_indices;
    thrust::host_vector<int> eids;

    std::vector<int> in_degrees;
    std::vector<int> out_degrees;

    CSR(std::vector<std::tuple<int, int>> edge_list, int num_nodes, bool is_edge_reverse);
    std::tuple<std::size_t, std::size_t, std::size_t> get_csr_ptrs();
    void label_edges();
    int find_edge_id(int src, int dst);
    void copy_label_edges(CSR new_csr);
    void print_csr_arrays();
    void print_graph();
};

bool sort_by_sec(const std::tuple<int, int> &a,
                 const std::tuple<int, int> &b)
{
    return std::tie(std::get<1>(a), std::get<0>(a)) <
           std::tie(std::get<1>(b), std::get<0>(b));
}

CSR::CSR(std::vector<std::tuple<int, int>> edge_list, int num_nodes, bool is_edge_reverse = false)
{
    if (is_edge_reverse)
        sort(edge_list.begin(), edge_list.end(), sort_by_sec);
    else
        sort(edge_list.begin(), edge_list.end());

    // initialising row_offset values all to -1
    row_offset.resize(num_nodes + 1);
    thrust::fill(row_offset.begin(), row_offset.end(), -1);
    row_offset[0] = 0;

    in_degrees.resize(num_nodes, 0);
    out_degrees.resize(num_nodes, 0);

    int current_src;
    int beg = 0;
    int end = 0;

    // iterating through the edge_list
    for (auto &edge : edge_list)
    {
        int src = is_edge_reverse ? std::get<1>(edge) : std::get<0>(edge);
        int dst = is_edge_reverse ? std::get<0>(edge) : std::get<1>(edge);

        // first edge
        if (beg == 0 && end == 0)
            current_src = src;

        // source node we are dealing with changes
        if (current_src != src)
        {
            // update row_offset
            row_offset[current_src] = beg;
            row_offset[current_src + 1] = end;

            current_src = src;
            beg = end;
        }

        // adding the dst node to the column indices
        // and incrementing the end range by 1
        column_indices.push_back(dst);
        end += 1;

        // updating the degree arrays
        out_degrees[src] += 1;
        in_degrees[dst] += 1;
    }

    row_offset[current_src + 1] = end;

    // removing the -1
    int curr_val = row_offset[0];
    for (int i = 1; i < row_offset.size(); ++i)
    {
        if (row_offset[i] != curr_val && row_offset[i] != -1)
            curr_val = row_offset[i];

        if (row_offset[i] == -1)
            row_offset[i] = curr_val;
    }
}

std::tuple<std::size_t, std::size_t, std::size_t> CSR::get_csr_ptrs()
{
    DEV_VEC row_offset_device = row_offset;
    DEV_VEC column_indices_device = column_indices;
    DEV_VEC eids_device = eids;

    std::tuple<std::size_t, std::size_t, std::size_t> t;
    std::get<0>(t) = (std::size_t)RAW_PTR(row_offset_device);
    std::get<1>(t) = (std::size_t)RAW_PTR(column_indices_device);
    std::get<2>(t) = (std::size_t)RAW_PTR(eids_device);
    return t;
}

int binary_search_idx(thrust::host_vector<int> vec, int start, int end, int elem)
{
    auto lower = std::lower_bound(vec.begin() + start, vec.begin() + end, elem);
    const bool found = lower != vec.begin() + end && *lower == elem;

    if (found)
        return std::distance(vec.begin(), lower);
    else
        return -1;
}

// int CSR::find_edge_id(int src, int dst)
// {

//     int beg = row_offset[src];
//     int end = row_offset[src + 1];

//     int col_idx = binary_search_idx(column_indices, beg, end, dst);

//     if (col_idx != -1)
//         return eids[col_idx];
//     else
//         return -1;
// }

int CSR::find_edge_id(int src, int dst)
{

    int beg = row_offset[src];
    int end = row_offset[src + 1];

    thrust::host_vector<int>::iterator col_idx = thrust::find(thrust::host, column_indices.begin() + beg, column_indices.begin() + end, dst);

    if (col_idx != column_indices.end())
    {
        int index = thrust::distance(column_indices.begin(), col_idx);
        return eids[index];
    }
    else
    {
        std::cout << "Ërror: Id not found\n";
        return -1;
    }
}

void CSR::label_edges()
{
    eids.resize(column_indices.size());
    thrust::sequence(eids.begin(), eids.end());
}

void CSR::copy_label_edges(CSR ref_csr)
{
    eids.resize(column_indices.size());

    int num_nodes = row_offset.size() - 1;
    for (int src = 0; src < num_nodes; ++src)
    {
        int beg = row_offset[src];
        int end = row_offset[src + 1];

        for (int dst_idx = beg; dst_idx < end; ++dst_idx)
        {
            int dst = column_indices[dst_idx];
            int id = ref_csr.find_edge_id(dst, src);
            eids[dst_idx] = id;
        }
    }
}

void CSR::print_csr_arrays()
{
    thrust::host_vector<int> h_row = row_offset;
    thrust::host_vector<int> h_col = column_indices;
    thrust::host_vector<int> h_eids = eids;

    cudaDeviceSynchronize();

    printf("\nRow offsets:\n");
    for (int i = 0; i < h_row.size(); ++i)
        printf("%d ", h_row[i]);

    printf("\n");

    printf("\nOut-degrees:\n");
    for (int i = 0; i < out_degrees.size(); ++i)
        printf("%d ", out_degrees[i]);

    printf("\nIn-degrees:\n");
    for (int i = 0; i < in_degrees.size(); ++i)
        printf("%d ", in_degrees[i]);

    printf("\nColumn Indices:\n");
    for (int i = 0; i < h_col.size(); ++i)
        printf("%d ", h_col[i]);

    printf("\nEids:\n");
    for (int i = 0; i < h_eids.size(); ++i)
        printf("%d ", h_eids[i]);

    printf("\n");
}

void CSR::print_graph()
{
    thrust::host_vector<int> h_row_offset = row_offset;
    thrust::host_vector<int> h_column_indices = column_indices;
    thrust::host_vector<int> h_eids = eids;

    int num_vertices = h_row_offset.size() - 1;

    // printing the graph matrix column indices
    for (int dst = 0; dst < num_vertices; ++dst)
        std::cout << "   " << dst << std::flush;

    printf("\n");

    for (int src = 0; src < num_vertices; ++src)
    {
        std::cout << src << " " << std::flush;
        int matrix_index = 0;

        int beg = h_row_offset[src];
        int end = h_row_offset[src + 1];

        for (int dst_idx = beg; dst_idx < end; ++dst_idx)
        {
            while (matrix_index < h_column_indices[dst_idx])
            {
                std::cout << "    " << std::flush;
                matrix_index++;
            }
            std::cout << " " << h_eids[dst_idx] << "  " << std::flush;
            matrix_index++;
        }

        for (int j = matrix_index; j < num_vertices; ++j)
            std::cout << "    " << std::flush;

        printf("\n");
    }
}

PYBIND11_MODULE(csr, m)
{
    m.doc() = "CPython module for CSR"; // optional module docstring

    py::class_<CSR>(m, "CSR")
        .def(py::init<std::vector<std::tuple<int, int>>, int, bool>(), py::arg("edge_list"), py::arg("num_nodes"), py::arg("is_edge_reverse") = false)
        .def("label_edges", &CSR::label_edges)
        .def("copy_label_edges", &CSR::copy_label_edges)
        .def("get_csr_ptrs", &CSR::get_csr_ptrs)
        .def("print_csr_arrays", &CSR::print_csr_arrays)
        .def("print_graph", &CSR::print_graph)
        .def_readwrite("row_offset", &CSR::row_offset)
        .def_readwrite("column_indices", &CSR::column_indices)
        .def_readwrite("eids", &CSR::eids)
        .def_readwrite("out_degrees", &CSR::out_degrees)
        .def_readwrite("in_degrees", &CSR::in_degrees)
        .def("__copy__", [](const CSR &self)
             { return CSR(self); })
        .def(
            "__deepcopy__", [](const CSR &self, py::dict)
            { return CSR(self); },
            "memo"_a);
}