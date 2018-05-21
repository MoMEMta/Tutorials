load_modules("MatrixElements/pp_x0_ZZ_4mu/build/libme_pp_x0_ZZ_4mu.so")

lepton_plus_1 = declare_input("lepton_plus_1")
lepton_plus_2 = declare_input("lepton_plus_2")
lepton_minus_1 = declare_input("lepton_minus_1")
lepton_minus_2 = declare_input("lepton_minus_2")

parameters = {
    energy = 13000.,
    higgs_width = 6.3823e-3, -- default width, can be changed from analysis script
    -- Path to param card to be changed from the analysis script;
    -- There is only card prepared for each set of signal couplings.
    param_card = "", 
}

inputs = {
    lepton_plus_1.reco_p4,
    lepton_minus_1.reco_p4,
    lepton_plus_2.reco_p4,
    lepton_minus_2.reco_p4,
    }

-- Build the partonic initial state
BuildInitialState.boost = {
    do_transverse_boost = true,
    particles = inputs,
}

-- Call matrix element on fully defined partonic event
MatrixElement.h_4f = {
    pdf = "CT10nlo",
    pdf_scale = 125.,
    matrix_element = "pp_x0_ZZ_4mu_HC_UFO_P1_Sigma_HC_UFO_gg_mupmupmummum",
    matrix_element_parameters = {
        card = parameter("param_card"),
    },
    override_parameters = {
        mdl_WX0 = parameter("higgs_width"),
    },
    initialState = "boost::partons",
    -- Matrix element expects mu(+)mu(+)mu(-)mu(-),
    -- whereas inputs are given as mu(+)mu(-)mu(+)mu(-),
    -- hence indexing has to be reordered:
    particles = {
        inputs = inputs,
        ids = {
            {
                pdg_id = -13,
                me_index = 1,
            },
            {
                pdg_id = 13,
                me_index = 3,
            },
            {
                pdg_id = -13,
                me_index = 2,
            },
            {
                pdg_id = 13,
                me_index = 4,
            },
        }
    },
}

-- Define quantity to be returned to MoMEMta
integrand("h_4f::output")
