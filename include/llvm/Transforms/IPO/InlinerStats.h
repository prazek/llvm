#ifndef LLVM_TRANSFORMS_IPO_INLINERSTATS_H
#define LLVM_TRANSFORMS_IPO_INLINERSTATS_H

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Function.h"
#include <vector>

/// InlinerStatistics - calculating and dumping statistics on performed inlines.
/// It calculates statistics summarized stats like:
/// (1) Number of inlined imported functions,
/// (2) Number of real inlined imported functions
/// (3) Number of real not external inlined functions
/// The difference between first and the second is that first stat counts
/// all performed inlines, and second one only the functions that really have
/// been inlined to some not imported function. Because llvm uses bottom-up
/// inliner, it is possible to e.g. import function A, B and then inline B to A,
/// and after this A might be too big to be inlined into some other function
/// that calls it. It calculates the real values by building graph, where
/// the nodes are functions, and edges are performed inlines.
/// Then starting from non external functions that have some inlined calls
/// inside, it walks to every inlined function and increment counter.
///
/// If `EnableListStats` is set to true, then it also dumps statistics
/// per each inlined function, sorted by the greatest inlines count like
/// - number of performed inlines
/// - number of performed real inlines
class InlinerStatistics {
private:
  struct InlineGraphNode {
    InlineGraphNode() = default;
    InlineGraphNode(InlineGraphNode&&) = default;
    InlineGraphNode(const InlineGraphNode&) = delete;
    InlineGraphNode &operator=(InlineGraphNode&&) = default;

    llvm::SmallVector<InlineGraphNode *, 8> InlinedFunctions;
    int16_t NumberOfInlines = 0;     // Incremented every direct inline.
    int16_t NumberOfRealInlines = 0; // Computed based on graph.
    bool Imported = false;
  };

  using NodesMapTy = llvm::DenseMap<const llvm::Function *, InlineGraphNode>;
  friend InlinerStatistics &getInlinerStatistics(bool EnableListStats);

public:
  void addInlinedFunction(llvm::Function *Fun, llvm::Function *Inlined);
  void dumpStats();

private:
  InlinerStatistics(bool EnableListStats);
  void calculateRealInlines();
  void dfs(InlineGraphNode *const GraphNode);

  using SortedNodesTy = std::vector<NodesMapTy::value_type>;
  // Clears NodesMap and returns vector of elements sorted by
  // (-NumberOfInlines, -NumberOfRealInlines, FunctioName).
  SortedNodesTy getSortedNodes();

private:
  NodesMapTy NodesMap;
  // Non external functions that have some other function inlined inside.
  std::vector<const llvm::Function *> NonExternalFunctions;
  bool EnableListStats;
};

/// Returns InlinerStatistics singleton.
InlinerStatistics &getInlinerStatistics(bool EnableListStats);

#endif // LLVM_TRANSFORMS_IPO_INLINERSTATS_H
