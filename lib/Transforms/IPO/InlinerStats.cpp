#include "llvm/Transforms/IPO/InlinerStats.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>

using namespace llvm;
InlinerStatistics::InlinerStatistics(bool EnableListStats)
    : EnableListStats(EnableListStats) {
  NonExternalFunctions.reserve(200);
}

void InlinerStatistics::addInlinedFunction(Function *Fun, Function *Inlined) {
  assert(Fun && Inlined);
  auto &FunNode = NodesMap[Fun];
  FunNode.Imported = Fun->getMetadata("thinlto_src_module") != nullptr;
  if (!FunNode.Imported)
    NonExternalFunctions.push_back(Fun);

  auto &InlinedNode = NodesMap[Inlined];
  InlinedNode.Imported = Inlined->getMetadata("thinlto_src_module") != nullptr;
  InlinedNode.NumberOfInlines++;
  FunNode.InlinedFunctions.push_back(&InlinedNode);
}

void InlinerStatistics::dumpStats() {
  calculateRealInlines();
  NonExternalFunctions.clear();

  int32_t NumberOFUniqueInlinedImportedFunctions = 0,
          NumberOfRealUniqueInlinedImportedFunctions = 0,
          NumberOFRealUniqueInlinedNotExternalFunctions = 0;

  auto SortedNodes = getSortedNodes();
  for (const auto &Node : SortedNodes) {
    if (Node.second.Imported) {
      NumberOFUniqueInlinedImportedFunctions +=
          (Node.second.NumberOfInlines > 0) * 1;
      NumberOfRealUniqueInlinedImportedFunctions +=
          (Node.second.NumberOfRealInlines > 0) * 1;
    } else {
      NumberOFRealUniqueInlinedNotExternalFunctions =
          (Node.second.NumberOfRealInlines > 0) * 1;
    }

    assert(Node.second.NumberOfInlines >= Node.second.NumberOfRealInlines);
    // No more inlined functions.
    if (Node.second.NumberOfInlines == 0)
      break;
    if (EnableListStats)
      dbgs() << "Inlined "
             << (Node.second.Imported ? "imported " : "not external ")
             << "function [" << Node.first->getName() << "]"
             << ": #inlines = " << Node.second.NumberOfInlines
             << ", #real_inlines = " << Node.second.NumberOfRealInlines << "\n";
  }

  dbgs() << "Number of inlined imported functions: "
         << NumberOFUniqueInlinedImportedFunctions
         << "\nNumber of real inlined imported functions: "
         << NumberOfRealUniqueInlinedImportedFunctions
         << "\nNumber of real not external inlined functions: "
         << NumberOFRealUniqueInlinedNotExternalFunctions << "\n";
}

void InlinerStatistics::calculateRealInlines() {
  for (const auto *F : NonExternalFunctions) {
    dfs(&NodesMap[F]);
  }
}

void InlinerStatistics::dfs(InlineGraphNode *const GraphNode) {
  for (auto *const InlinedFunctionNode : GraphNode->InlinedFunctions) {
    InlinedFunctionNode->NumberOfRealInlines++;
    dfs(InlinedFunctionNode);
  }
}

InlinerStatistics::SortedNodesTy InlinerStatistics::getSortedNodes() {
  SortedNodesTy SortedNodes(std::make_move_iterator(NodesMap.begin()),
                            std::make_move_iterator(NodesMap.end()));
  NodesMap.clear();

  std::sort(SortedNodes.begin(), SortedNodes.end(),
            [](const SortedNodesTy::value_type &Lhs,
               const SortedNodesTy::value_type &Rhs) {
              if (Lhs.second.NumberOfInlines != Rhs.second.NumberOfInlines)
                return Lhs.second.NumberOfInlines > Rhs.second.NumberOfInlines;
              if (Lhs.second.NumberOfRealInlines !=
                  Rhs.second.NumberOfRealInlines)
                return Lhs.second.NumberOfRealInlines >
                       Rhs.second.NumberOfRealInlines;
              return Lhs.first->getName() < Rhs.first->getName();
            });
  return SortedNodes;
}

InlinerStatistics &getInlinerStatistics(bool EnableListStats) {
  static InlinerStatistics Graph(EnableListStats);
  return Graph;
}
