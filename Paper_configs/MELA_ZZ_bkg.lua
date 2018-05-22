load_modules("MatrixElements/pp_4mu/build/libpp_4mu.so")

lepton_plus_1 = declare_input("lepton_plus_1")
lepton_plus_2 = declare_input("lepton_plus_2")
lepton_minus_1 = declare_input("lepton_minus_1")
lepton_minus_2 = declare_input("lepton_minus_2")

parameters = {
    energy = 13000.,
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
MatrixElement.pp_4f = {
    pdf = "CT10nlo",
    pdf_scale = 91.,
    matrix_element = "pp_4mu_sm_P1_Sigma_sm_uux_mupmummupmum",
    matrix_element_parameters = {
        card = "MatrixElements/pp_4mu/Cards/param_card.dat"
    },
    initialState = "boost::partons",
    particles = {
        inputs = inputs,
        ids = {
            {
                pdg_id = -13,
                me_index = 1,
            },
            {
                pdg_id = 13,
                me_index = 2,
            },
            {
                pdg_id = -13,
                me_index = 3,
            },
            {
                pdg_id = 13,
                me_index = 4,
            },
        }
    },
}

-- Define quantity to be returned to MoMEMta
integrand("pp_4f::output")
