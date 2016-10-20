/*
 *  MoMEMta: a modular implementation of the Matrix Element Method
 *  Copyright (C) 2016  Universite catholique de Louvain (UCL), Belgium
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#include <momemta/ConfigurationReader.h>
#include <momemta/Logging.h>
#include <momemta/MoMEMta.h>
#include <momemta/Unused.h>

#include <TTree.h>
#include <TChain.h>
#include <Math/PtEtaPhiM4D.h>
#include <Math/LorentzVector.h>
#include <TLorentzVector.h>

#include <chrono>

using namespace std::chrono;

/*
 * Example executable file loading an input sample of events,
 * computing weights using MoMEMta in the fully-leptonic WW hypothesis,
 * and saving these weights along with a copy of the event content in an output file.
 */

int main(int argc, char** argv) {

    UNUSED(argc);
    UNUSED(argv);

    /*
     * Load events from input file, retrieve reconstructed particles and MET
     */
    TChain chain("T");
    chain.Add("../WW_FullyLeptonic/WW_20ev.root");

    TLorentzVector *lepton1 = nullptr;
    TLorentzVector *lepton2 = nullptr;
    int charge_lep1=0;

    chain.SetBranchAddress("lepton1", &lepton1);
    chain.SetBranchAddress("lepton2", &lepton2);
    chain.SetBranchAddress("charge_lep1", &charge_lep1);
    int N = chain.GetEntries();
    
    /*
     * Define output TTree, which will be a clone of the input tree,
     * with the addition of the weights we're computing (including uncertainty and computation time)
     */
    TTree* out_tree = chain.CloneTree(0);
    double weight_WW, weight_WW_err, weight_WW_time;
    out_tree->Branch("weight_WW", &weight_WW);
    out_tree->Branch("weight_WW_err", &weight_WW_err);
    out_tree->Branch("weight_WW_time", &weight_WW_time);
 
    /*
     * Prepare MoMEMta to compute the weights
     */
    // Set MoMEMta's logging level to `debug`
    logging::set_level(logging::level::debug);

    // Construct the ConfigurationReader from the Lua file
    ConfigurationReader configuration("../WW_FullyLeptonic/WW_FullyLeptonic.lua");

    // Instantiate MoMEMta using a **frozen** configuration
    MoMEMta weight(configuration.freeze());

    /*
     * Loop over all input events
     */
    for (int64_t entry = 0; entry < N; entry++) {
        chain.GetEntry(entry);
        
        LorentzVector lep1_p4 { lepton1->Px(), lepton1->Py(), lepton1->Pz(), lepton1->E() };
        LorentzVector lep2_p4 { lepton2->Px(), lepton2->Py(), lepton2->Pz(), lepton2->E() };
        int charge_l1 = charge_lep1;

        if (charge_l1 < 0)
            std::swap(lep1_p4, lep2_p4);

        auto start_time = system_clock::now();
        // Compute the weights!
        std::vector<std::pair<double, double>> weights = weight.computeWeights({lep1_p4,lep2_p4});
        auto end_time = system_clock::now();

        // Retrieve the weight and uncertainty
        weight_WW = weights.back().first;
        weight_WW_err = weights.back().second;
        weight_WW_time = std::chrono::duration_cast<milliseconds>(end_time - start_time).count();

        LOG(debug) << "Event " << entry << " result: " << weight_WW << " +- " << weight_WW_err;
        LOG(info) << "Weight computed in " << weight_WW_time << "ms";

        out_tree->Fill();
    }

    //Save our output TTree
    out_tree->SaveAs("WW_weighted.root");

    return 0;
}
