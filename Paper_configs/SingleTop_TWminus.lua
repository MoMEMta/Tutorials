load_modules('MatrixElements/ME_gb_tw_mup_mum/libme_ME_gb_tw_mup_mum.so')

cuba = {
    -- Require 2% precision on weight
    relative_accuracy = 0.02,
    -- But limit number of evaluations if precision is not reached
    max_eval = 500000,
    n_start = 50000,
}

parameters = {
    energy = 13000.,
    top_mass = 173.,
    top_width = 1.491500,
    W_mass = 80.419002,
    W_width = 2.047600,
    
    ME_card = 'MatrixElements/ME_gb_tw_mup_mum/Cards/param_card.dat',
}

local lep_p = declare_input("lepton+")
local lep_m = declare_input("lepton-")
local bjet = declare_input("jet")

-- Dummy massless 4-vector we'll use to integrate over its degrees of freedom
local dummy_neutrino = declare_input("dummy_neutrino")

-- Generate W and top invariant masses according to their Breit-Wigner
BreitWignerGenerator.flatter_s12 = {
    ps_point = add_dimension(),
    mass = parameter('W_mass'),
    width = parameter('W_width')
}
BreitWignerGenerator.flatter_s123 = {
    ps_point = add_dimension(),
    mass = parameter('top_mass'),
    width = parameter('top_width')
}
BreitWignerGenerator.flatter_s45 = {
    ps_point = add_dimension(),
    mass = parameter('W_mass'),
    width = parameter('W_width')
}

-- Extremely simplified transfer functions on lepton and b-jet energies
GaussianTransferFunctionOnEnergy.tf_lep_m = {
    ps_point = add_dimension(),
    reco_particle = lep_m.reco_p4,
    sigma = 0.02,
    sigma_range = 5.,
}
lep_m.set_gen_p4("tf_lep_m::output")

GaussianTransferFunctionOnEnergy.tf_lep_p = {
    ps_point = add_dimension(),
    reco_particle = lep_p.reco_p4,
    sigma = 0.02,
    sigma_range = 5.,
}
lep_p.set_gen_p4("tf_lep_p::output")

GaussianTransferFunctionOnEnergy.tf_bjet = {
    ps_point = add_dimension(),
    reco_particle = bjet.reco_p4,
    sigma = 0.15,
    sigma_range = 5.,
}
bjet.set_gen_p4("tf_bjet::output")

-- We integrate over the neutrino's Phi angle: use a "flat" transfer function (1 everywhere)
-- The initial "reco" 4-vector is random, it only needs to have the right mass
FlatTransferFunctionOnPhi.neutrino_phi_fixed = {
    ps_point = add_dimension(),
    reco_particle = dummy_neutrino.reco_p4,
}

-- Change of variables: align Top and W (from Top) propagators with grid!, i.e.:
--      from the neutrinos's Theta angle and momentum,
--      to the W and Top masses.
-- The remaining d.o.f. (neutrino Phi) was taken care of by the "flat" T.F.
-- The module "spits out" a completely specified neutrino 4-vector, using as input the generated Top and W masses
SecondaryBlockB.sb_b = {
    p1 = 'neutrino_phi_fixed::output',
    p2 = lep_p.gen_p4,
    p3 = bjet.gen_p4,
    s12 = 'flatter_s12::s',
    s123 = 'flatter_s123::s',
}

StandardPhaseSpace.phaseSpaceOut = {
    particles = {lep_p.gen_p4, bjet.gen_p4, lep_m.gen_p4}
}

-- Iterate over solutions from secondary block
Looper.looper_sb_b = {
    solutions = "sb_b::solutions",
    path = Path("met_substracted", "blockb", "looper_blockb")
}

    -- Define X = MET - neutrino (from W from Top)
    -- We'll use X to fix the other neutrino's transverse momentum
    VectorLinearCombinator.met_substracted = {
        inputs = {'met::p4', 'looper_sb_b::particles/1'},
        coefficients = {1., -1.}
    }
   
    -- "Main" change of variables:
    -- Change 
    --      from the other neutrino's d.o.f.
    --      to the W's mass
    -- Take care of momentum conservation in the process (i.e., also removes the 2 Bjorken-x variables).
    -- The module "spits out" the other neutrino's completely specified 4-vector
    BlockB.blockb = {
        p2 = lep_m.gen_p4,
        pT_is_met = true,
        met = 'met_substracted::output',
        s12 = 'flatter_s45::s',
    }

    -- Iterate over solutions from main block
    Looper.looper_blockb = {
        solutions = "blockb::solutions",
        path = Path("boost", "twMinus", "integrand")
    }

        -- Final state parton event is now fully specified
        full_inputs = {lep_p.gen_p4, bjet.gen_p4, lep_m.gen_p4, 'looper_sb_b::particles/1', 'looper_blockb::particles/1'}

        -- Build initial state using momentum conservation
        BuildInitialState.boost = {
            do_transverse_boost = true,
            particles = full_inputs
        }

        -- All terms that have to be multiplied together with the matrix element to define the integrand
        jacobians = {'flatter_s12::jacobian', 'flatter_s123::jacobian', 'flatter_s45::jacobian', 'neutrino_phi_fixed::TF_times_jacobian', 'looper_blockb::jacobian', 'looper_sb_b::jacobian',
                    'tf_lep_m::TF_times_jacobian', 'tf_lep_p::TF_times_jacobian', 'tf_bjet::TF_times_jacobian', 'phaseSpaceOut::phase_space'}

        MatrixElement.twMinus = {
          pdf = 'CT10nlo',
          pdf_scale = parameter('top_mass'),

          matrix_element = 'ME_gb_tw_mup_mum_sm_no_b_mass',
          matrix_element_parameters = {
              card =  parameter('ME_card'),
          },

          initialState = 'boost::partons',

          particles = {
            inputs = full_inputs,
            ids = { 
              {
                pdg_id = -13,
                me_index = 1,
              },

              {
                pdg_id = 5,
                me_index = 3,
              },

              {
                pdg_id = 13,
                me_index = 4,
              },

              {
                pdg_id = 14,
                me_index = 2,
              },

              {
                pdg_id = -14,
                me_index = 5,
              }
            }
          },

          jacobians = jacobians
        }

        -- Sum answer over the two nested loops over solution
        DoubleLooperSummer.integrand = {
            input = "twMinus::output"
        }

-- End of loops, define integrand to return to integrator
integrand("integrand::sum")
