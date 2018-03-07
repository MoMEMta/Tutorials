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
#include <TTreeReader.h>
#include <TTreeReaderValue.h>
#include <Math/PtEtaPhiM4D.h>
#include <Math/LorentzVector.h>

#include <chrono>
#include <memory>

using namespace std::chrono;

using LorentzVectorM = ROOT::Math::LorentzVector<ROOT::Math::PtEtaPhiM4D<float>>;

/*
 * Example executable file loading an input sample of events,
 * computing weights using MoMEMta in the fully-leptonic ttbar hypothesis,
 * and saving these weights along with a copy of the event content in an output file.
 */

void normalizeInput(LorentzVector& p4) {
    if (p4.M() > 0)
        return;

    // Increase the energy until M is positive
    p4.SetE(p4.P());
    while (p4.M2() < 0) {
        double delta = p4.E() * 1e-5;
        p4.SetE(p4.E() + delta);
    };
}

int main(int argc, char** argv) {

    UNUSED(argc);
    UNUSED(argv);

    using std::swap;

    /*
     * Load events from input file, retrieve reconstructed particles and MET
     */
    TChain chain("t");
    chain.Add("../TTbar_FullyLeptonic/tt_20evt.root");
    TTreeReader myReader(&chain);

    TTreeReaderValue<LorentzVectorM> lep_plus_p4M(myReader, "lep1_p4");
    TTreeReaderValue<LorentzVectorM> lep_minus_p4M(myReader, "lep2_p4");
    TTreeReaderValue<LorentzVectorM> bjet1_p4M(myReader, "bjet1_p4");
    TTreeReaderValue<LorentzVectorM> bjet2_p4M(myReader, "bjet2_p4");
    TTreeReaderValue<float> MET_met(myReader, "MET_met");
    TTreeReaderValue<float> MET_phi(myReader, "MET_phi");
    TTreeReaderValue<int> leading_lep_PID(myReader, "leadLepPID");

    /*
     * Define output TTree, which will be a clone of the input tree,
     * with the addition of the weights we're computing (including uncertainty and computation time)
     */
    std::unique_ptr<TTree> out_tree(chain.CloneTree(0));
    double weight_TT, weight_TT_err, weight_TT_time;
    out_tree->Branch("weight_TT", &weight_TT);
    out_tree->Branch("weight_TT_err", &weight_TT_err);
    out_tree->Branch("weight_TT_time", &weight_TT_time);

    /*
     * Prepare MoMEMta to compute the weights
     */
    // Set MoMEMta's logging level to `debug`
    logging::set_level(logging::level::debug);

    // Construct the ConfigurationReader from the Lua file
    ConfigurationReader configuration("../TTbar_FullyLeptonic/TTbar_FullyLeptonic.lua");

    // Instantiate MoMEMta using a **frozen** configuration
    MoMEMta weight(configuration.freeze());

    /*
     * Loop over all input events
     */
    while (myReader.Next()) {
        /*
         * Prepare the LorentzVectors passed to MoMEMta:
         * In the input file they are written in the PtEtaPhiM<float> basis,
         * while MoMEMta expects PxPyPzE<double>, so we have to perform this change of basis:
         *
         * We define here Particles, allowing MoMEMta to correctly map the inputs to the configuration file.
         * The string identifier used here must be the same as used to declare the inputs in the config file
         */
        momemta::Particle lep_plus("lepton1",  LorentzVector { lep_plus_p4M->Px(), lep_plus_p4M->Py(), lep_plus_p4M->Pz(), lep_plus_p4M->E() });
        momemta::Particle lep_minus("lepton2", LorentzVector { lep_minus_p4M->Px(), lep_minus_p4M->Py(), lep_minus_p4M->Pz(), lep_minus_p4M->E() });
        momemta::Particle bjet1("bjet1", LorentzVector { bjet1_p4M->Px(), bjet1_p4M->Py(), bjet1_p4M->Pz(), bjet1_p4M->E() });
        momemta::Particle bjet2("bjet2", LorentzVector { bjet2_p4M->Px(), bjet2_p4M->Py(), bjet2_p4M->Pz(), bjet2_p4M->E() });

        // Due to numerical instability, the mass can sometimes be negative. If it's the case, change the energy in order to be mass-positive
        normalizeInput(lep_plus.p4);
        normalizeInput(lep_minus.p4);
        normalizeInput(bjet1.p4);
        normalizeInput(bjet2.p4);

        LorentzVectorM met_p4M { *MET_met, 0, *MET_phi, 0 };
        LorentzVector met_p4 { met_p4M.Px(), met_p4M.Py(), met_p4M.Pz(), met_p4M.E() };
        
        // Ensure the leptons are given in the correct order w.r.t their charge 
        if (*leading_lep_PID < 0)
            swap(lep_plus, lep_minus);

        auto start_time = system_clock::now();
        // Compute the weights!
        std::vector<std::pair<double, double>> weights = weight.computeWeights({lep_minus, bjet1, lep_plus, bjet2}, met_p4);
        auto end_time = system_clock::now();

        // Retrieve the weight and uncertainty
        weight_TT = weights.back().first;
        weight_TT_err = weights.back().second;
        weight_TT_time = std::chrono::duration_cast<milliseconds>(end_time - start_time).count();

        LOG(debug) << "Event " << myReader.GetCurrentEntry() << " result: " << weight_TT << " +- " << weight_TT_err;
        LOG(info) << "Weight computed in " << weight_TT_time << "ms";

        out_tree->Fill();
    }

    // Save our output TTree
    out_tree->SaveAs("tt_20evt_weighted.root");

    return 0;
}
