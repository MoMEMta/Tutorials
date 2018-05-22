-- Register inputs
local lepton1 = declare_input("lepton1")
local lepton2 = declare_input("lepton2")

-- B jets coming from top decays
local top_bjet1 = declare_input("top_bjet1")
local top_bjet2 = declare_input("top_bjet2")

-- 2 others B jets
local bjet1 = declare_input("higgs_bjet1") -- Keep the same name as in the ttH configuration for ease of use
local bjet2 = declare_input("higgs_bjet2")

-- Permutates over all possible bjets combinations using an extra variable of integration,
-- depending on "DO_PERM" parameter set in the analysis script before leading the .lua
DO_PERM = DO_PERM == nil and true or DO_PERM
if DO_PERM then
    add_reco_permutations(top_bjet1, top_bjet2, bjet1, bjet2)
end

parameters = {
    energy = 13000.,
    top_mass = 173.,
    top_width = 1.491500,
    W_mass = 80.419002,
    W_width = 2.047600,
    -- Can be useful for debugging the computation graph:
    -- export_graph_as = 'ttbb_momemta_graph.dot'
}

cuba = {
    -- Request 1% accurary in the weights
    relative_accuracy = 0.01,
    verbosity = 2,
    n_start =  30000,
    max_eval = 30000 * 30,
    -- Switch to Divonne integration algorithm
    algorithm = "divonne",
}

-- Switch for using narrow-width approximation (NWA) or not for the top and W propagators
-- NWA means fixing their masses to their "true" mass, instead of integrating over them.
NWA = true

if NWA then

    NarrowWidthApproximation.flatter_top_s13 = {
        mass = parameter('W_mass'),
        width = parameter('W_width')
    }

    NarrowWidthApproximation.flatter_top_s134 = {
        mass = parameter('top_mass'),
        width = parameter('top_width')
    }

    NarrowWidthApproximation.flatter_top_s25 = {
        mass = parameter('W_mass'),
        width = parameter('W_width')
    }

    NarrowWidthApproximation.flatter_top_s256 = {
        mass = parameter('top_mass'),
        width = parameter('top_width')
    }

else

    BreitWignerGenerator.flatter_top_s13 = {
        -- add_dimension() generates an input tag of type `cuba::ps_points/i`
        -- where `i` is automatically incremented each time the function is called.
        -- This function allows MoMEMta to track how many dimensions are needed for the integration.
        ps_point = add_dimension(),
        mass = parameter('W_mass'),
        width = parameter('W_width')
    }

    BreitWignerGenerator.flatter_top_s134 = {
        ps_point = add_dimension(),
        mass = parameter('top_mass'),
        width = parameter('top_width')
    }

    BreitWignerGenerator.flatter_top_s25 = {
        ps_point = add_dimension(),
        mass = parameter('W_mass'),
        width = parameter('W_width')
    }

    BreitWignerGenerator.flatter_top_s256 = {
        ps_point = add_dimension(),
        mass = parameter('top_mass'),
        width = parameter('top_width')
    }

end

-- Extremely simplidied transfer function on b-jet energy,
-- take 15% resolution on b-jets
GaussianTransferFunctionOnEnergy.tf_top_bjet1 = {
    ps_point = add_dimension(),
    reco_particle = top_bjet1.reco_p4,
    sigma = 0.15,
}

GaussianTransferFunctionOnEnergy.tf_top_bjet2 = {
    ps_point = add_dimension(),
    reco_particle = top_bjet2.reco_p4,
    sigma = 0.15,
}

GaussianTransferFunctionOnEnergy.tf_bjet1 = {
    ps_point = add_dimension(),
    reco_particle = bjet1.reco_p4,
    sigma = 0.15,
}

GaussianTransferFunctionOnEnergy.tf_bjet2 = {
    ps_point = add_dimension(),
    reco_particle = bjet2.reco_p4,
    sigma = 0.15,
}

top_bjet1.set_gen_p4("tf_top_bjet1::output")
top_bjet2.set_gen_p4("tf_top_bjet2::output")
bjet1.set_gen_p4("tf_bjet1::output")
bjet2.set_gen_p4("tf_bjet2::output")

-- If set_gen_p4 is not called, gen_p4 == reco_p4, i.e. leptons are taken as they are measured
inputs = {
    lepton1.gen_p4,
    top_bjet1.gen_p4,
    lepton2.gen_p4,
    top_bjet2.gen_p4,
    bjet1.gen_p4,
    bjet2.gen_p4
}

StandardPhaseSpace.phaseSpaceOut = {
    particles = inputs -- only on visible particles
}

-- Use Block D for the ttbar part
BlockD.tt_block = {
    p3 = lepton1.gen_p4,
    p4 = top_bjet1.gen_p4,
    p5 = lepton2.gen_p4,
    p6 = top_bjet2.gen_p4,

    pT_is_met = true,

    s13 = 'flatter_top_s13::s', -- W
    s134 = 'flatter_top_s134::s', -- top
    s25 = 'flatter_top_s25::s', -- W
    s256 = 'flatter_top_s256::s', -- top

    branches = {bjet1.gen_p4, bjet2.gen_p4}
}

-- Up to four solutions here. We need to loop over these solutions

Looper.tt_looper = {
    solutions = "tt_block::solutions",
    path = Path("boost", "ttbb_me", "integrand")
}

    full_inputs = {
        lepton1.gen_p4,
        top_bjet1.gen_p4,
        lepton2.gen_p4,
        top_bjet2.gen_p4,
        'tt_looper::particles/1', -- The two neutrinos reconstructed by Block D
        'tt_looper::particles/2',
        bjet1.gen_p4,
        bjet2.gen_p4,
    }

    BuildInitialState.boost = {
        do_transverse_boost = true,
        particles = full_inputs
    }

    jacobians = {
        'flatter_top_s13::jacobian', 'flatter_top_s134::jacobian', 'flatter_top_s25::jacobian', 'flatter_top_s256::jacobian', 
        --'tf_lepton1::TF_times_jacobian', 'tf_lepton2::TF_times_jacobian',
        'tf_top_bjet1::TF_times_jacobian', 'tf_top_bjet2::TF_times_jacobian', 'tf_bjet1::TF_times_jacobian', 'tf_bjet2::TF_times_jacobian', 
        'phaseSpaceOut::phase_space', 
        'tt_looper::jacobian'
    }

    -- Call the matrix element
    MatrixElement.ttbb_me = {
      pdf = 'CT10nlo',
      pdf_scale = 2. * parameters.top_mass,

      matrix_element = 'pp_ttbb_TTToFullyLeptonic_sm_P1_Sigma_sm_gg_epvebemvexbxbbx',
      matrix_element_parameters = {
          card = 'MatrixElement/pp_ttbb_TTToFullyLeptonic/Cards/param_card.dat'
      },

      override_parameters = {
          mdl_MT = parameter('top_mass'),
          mdl_WT = parameter('top_width'),
          mdl_WW = parameter('W_width')
      },

      initialState = 'boost::partons',

      particles = {
        inputs = full_inputs,
        ids = {
          {
            pdg_id = -11,
            me_index = 1,
          },

          {
            pdg_id = 5,
            me_index = 3,
          },

          {
            pdg_id = 11,
            me_index = 4,
          },

          {
            pdg_id = -5,
            me_index = 6,
          },

          {
            pdg_id = 12,
            me_index = 2,
          },

          {
            pdg_id = -12,
            me_index = 5,
          },

          {
            pdg_id = 5,
            me_index = 7,
          },

          {
            pdg_id = -5,
            me_index = 8,
          }
        }
      },

      jacobians = jacobians
    }

    -- Compute the integrand as the sum of the output of the ME module for all solutions
    DoubleLooperSummer.integrand = {
        input = "ttbb_me::output"
    }

-- End of loop
integrand("integrand::sum")
